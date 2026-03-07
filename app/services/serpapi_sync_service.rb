require 'cgi'
require 'json'
require 'net/http'
require 'set'

class SerpapiSyncService
  DEFAULT_CITIES = %w[
    mumbai
    delhi
    bengaluru
    hyderabad
    chennai
    kolkata
    pune
    ahmedabad
    kochi
    jaipur
    lucknow
    chandigarh
  ].freeze

  CITY_LABELS = {
    'mumbai' => 'Mumbai',
    'delhi' => 'Delhi',
    'bengaluru' => 'Bengaluru',
    'hyderabad' => 'Hyderabad',
    'chennai' => 'Chennai',
    'kolkata' => 'Kolkata',
    'pune' => 'Pune',
    'ahmedabad' => 'Ahmedabad',
    'kochi' => 'Kochi',
    'jaipur' => 'Jaipur',
    'lucknow' => 'Lucknow',
    'chandigarh' => 'Chandigarh'
  }.freeze

  def self.sync!
    new.sync!
  end

  def initialize
    @api_key = ENV['SERPAPI_KEY'].to_s.strip
    @omdb_api_key = ENV['OMDB_API_KEY'].to_s.strip
    @city_slugs = ENV.fetch('SERPAPI_CITIES', DEFAULT_CITIES.join(',')).split(',').map { |c| c.strip.downcase }.reject(&:blank?).uniq
    @cache_ttl_hours = ENV.fetch('SERPAPI_CACHE_TTL_HOURS', '6').to_i
    @refresh_cooldown_minutes = ENV.fetch('SERPAPI_REFRESH_COOLDOWN_MINUTES', '30').to_i
    @max_movie_age_days = ENV.fetch('SERPAPI_MAX_MOVIE_AGE_DAYS', '240').to_i
    @require_omdb = ENV.fetch('SERPAPI_REQUIRE_OMDB', 'true') == 'true'
    @force_refresh = ENV.fetch('SERPAPI_FORCE_REFRESH', 'false') == 'true'
    @seen_titles = []
    @movie_cities = Hash.new { |h, k| h[k] = Set.new }
    @city_movie_times = Hash.new { |h, k| h[k] = [] }
    @omdb_cache = {}
  end

  def sync!
    raise 'SERPAPI_KEY is missing' if @api_key.blank?

    city_to_records = fetch_city_records
    raise 'No movie titles found from SerpAPI source.' if city_to_records.values.flatten.empty?

    city_to_records.each do |city_slug, records|
      records.each do |record|
        movie = upsert_movie(record)
        next unless movie

        @movie_cities[movie.title] << city_slug
        @city_movie_times[[movie.title, city_slug]] = record[:times]
      end
    end

    raise 'No valid movies after enrichment filters.' if @movie_cities.empty?

    target_cities = @movie_cities.values.flat_map(&:to_a).uniq
    ensure_city_inventory!(target_cities)
    reset_future_showtimes(target_cities)
    generate_upcoming_showtimes
  end

  private

  def fetch_city_records
    @city_slugs.each_with_object({}) do |city_slug, out|
      payload = city_payload(city_slug)
      next if payload.blank?

      records = extract_city_movies(payload)
      out[city_slug] = records if records.any?
    rescue StandardError => e
      Rails.logger.warn("SerpAPI city skipped for #{city_slug}: #{e.message}")
    end
  end

  def city_payload(city_slug)
    if !@force_refresh && cache_fresh?(city_slug)
      return read_city_cache(city_slug)
    end

    if !@force_refresh && cooldown_active?(city_slug) && city_cache_path(city_slug).exist?
      return read_city_cache(city_slug)
    end

    payload = fetch_city_payload_from_api(city_slug)
    write_city_cache(city_slug, payload)
    write_city_refresh_stamp(city_slug)
    payload
  rescue StandardError => e
    Rails.logger.warn("SerpAPI live fetch failed for #{city_slug}: #{e.message}")
    read_city_cache(city_slug)
  end

  def fetch_city_payload_from_api(city_slug)
    city_name = city_label(city_slug)
    query = URI.encode_www_form(
      engine: 'google',
      q: "movies in #{city_name}",
      location: "#{city_name}, India",
      google_domain: 'google.co.in',
      gl: 'in',
      hl: 'en',
      tbm: 'mov',
      api_key: @api_key
    )
    uri = URI("https://serpapi.com/search.json?#{query}")
    response = Net::HTTP.get_response(uri)
    raise "HTTP #{response.code}" if response.code.to_i >= 400

    JSON.parse(response.body)
  end

  def extract_city_movies(payload)
    records = []
    seen = Set.new

    deep_movie_nodes(payload).each do |node|
      title = clean(node['title'] || node['name'])
      next if title.blank?
      next if title.length < 2
      next if likely_noise_title?(title)
      next if seen.include?(title.downcase)

      seen << title.downcase
      records << {
        title: title,
        times: extract_times(node),
        poster_url: normalized_url(node['thumbnail'] || node['poster'] || node['image']),
        language: clean(node['language']),
        rating: clean(node['rating']) || clean(node['content_rating'])
      }
    end

    records
  end

  def deep_movie_nodes(obj, path = [])
    case obj
    when Array
      obj.flat_map { |item| deep_movie_nodes(item, path) }
    when Hash
      nodes = []
      title = obj['title'] || obj['name']
      contextual = (path + obj.keys).map(&:to_s).join(' ').downcase
      has_movie_context = contextual.include?('movie') || contextual.include?('showtime') || contextual.include?('cinema')
      if title.present? && has_movie_context
        nodes << obj
      end
      obj.each do |k, v|
        nodes.concat(deep_movie_nodes(v, path + [k]))
      end
      nodes
    else
      []
    end
  end

  def likely_noise_title?(title)
    lowered = title.downcase
    lowered.include?('bookmyshow') ||
      lowered.include?('showtimes') ||
      lowered.include?('cinema near') ||
      lowered.include?('movie tickets')
  end

  def extract_times(node)
    raw = []
    collect_values(node, raw)
    raw.flat_map { |text| parse_times_from_text(text) }.uniq
  end

  def collect_values(obj, out)
    case obj
    when Array
      obj.each { |item| collect_values(item, out) }
    when Hash
      obj.each_value { |v| collect_values(v, out) }
    when String
      out << obj
    end
  end

  def parse_times_from_text(text)
    str = text.to_s
    am_pm = str.scan(/\b([0-1]?\d:[0-5]\d)\s?(AM|PM)\b/i).map { |hhmm, ampm| "#{hhmm} #{ampm.upcase}" }
    return am_pm if am_pm.any?

    str.scan(/\b([01]?\d|2[0-3]):([0-5]\d)\b/).map { |h, m| format('%02d:%02d', h.to_i, m.to_i) }
  end

  def upsert_movie(record)
    title = record[:title]
    omdb = omdb_for(title)
    return nil if @require_omdb && omdb.blank?

    release_date = parse_release_date(omdb&.dig('Released'))
    return nil if stale_release?(release_date)

    movie = Movie.find_or_initialize_by(title: title)
    movie.assign_attributes(
      description: clean(omdb&.dig('Plot')) || movie.description || 'Synopsis currently unavailable from source.',
      duration: parse_runtime(omdb&.dig('Runtime')) || movie.duration || 130,
      release_date: release_date || movie.release_date || Date.current,
      genre: clean(omdb&.dig('Genre')) || movie.genre || 'Drama',
      rating: normalize_rating(omdb&.dig('Rated')) || movie.rating,
      language: normalize_language(omdb&.dig('Language')) || clean(record[:language]) || movie.language || 'Hindi',
      poster_url: normalized_url(omdb&.dig('Poster')) || normalized_url(record[:poster_url]) || movie.poster_url,
      trailer_url: movie.youtube_trailer_url.presence || movie.trailer_url.presence || youtube_search_url(title),
      cast: clean(omdb&.dig('Actors')) || movie.cast,
      director: clean(omdb&.dig('Director')) || movie.director
    )
    movie.save!
    @seen_titles << movie.title
    movie
  end

  def omdb_for(title)
    return nil if title.blank? || @omdb_api_key.blank?

    @omdb_cache[title] ||= begin
      uri = URI('http://www.omdbapi.com/')
      uri.query = URI.encode_www_form(t: title, apikey: @omdb_api_key)
      response = Net::HTTP.get_response(uri)
      unless response.is_a?(Net::HTTPSuccess)
        nil
      else
        json = JSON.parse(response.body)
        json['Response'] == 'True' ? json : nil
      end
    rescue StandardError
      nil
    end
  end

  def stale_release?(release_date)
    return false if @max_movie_age_days <= 0
    return false if release_date.blank?

    release_date < @max_movie_age_days.days.ago.to_date
  end

  def parse_runtime(value)
    minutes = value.to_s[/\d+/]&.to_i
    minutes.to_i.positive? ? minutes : nil
  end

  def normalize_rating(value)
    raw = clean(value)
    return nil if raw.blank?

    map = {
      'U' => 'U',
      'UA' => 'U/A',
      'U/A' => 'U/A',
      'A' => 'A',
      'PG' => 'PG',
      'PG-13' => 'PG-13',
      'R' => 'R'
    }
    map[raw.upcase] || map[raw]
  end

  def normalize_language(value)
    clean(value.to_s.split(',').first)
  end

  def parse_release_date(value)
    return nil if value.blank? || value == 'N/A'

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def normalized_url(value)
    return nil if value.blank? || value == 'N/A'

    url = value.to_s.strip
    return "https:#{url}" if url.start_with?('//')
    return "https://www.google.com#{url}" if url.start_with?('/')

    url
  end

  def clean(value)
    value.to_s.strip.presence
  end

  def youtube_search_url(title)
    "https://www.youtube.com/results?search_query=#{CGI.escape("#{title} official trailer")}"
  end

  def ensure_city_inventory!(city_slugs)
    city_slugs.each do |city_slug|
      city_name = city_label(city_slug)
      theater = Theater.find_or_create_by!(name: "Cinema #{city_name}", city: city_name) do |t|
        t.location = "#{city_name} Central"
      end
      next if theater.screens.exists?

      Screen.create!(name: '1', capacity: 150, theater: theater)
      Screen.create!(name: '2', capacity: 120, theater: theater)
    end
  end

  def reset_future_showtimes(city_slugs)
    city_names = city_slugs.map { |slug| city_label(slug) }.uniq
    theater_ids = Theater.where(city: city_names).pluck(:id)
    return if theater_ids.empty?

    Showtime.where(theater_id: theater_ids).where('start_time > ?', Time.current).delete_all
  end

  def generate_upcoming_showtimes
    @movie_cities.each do |title, city_slugs|
      movie = Movie.find_by(title: title)
      next unless movie

      city_slugs.each do |city_slug|
        screen = city_screens(city_slug).sample
        next unless screen

        times = @city_movie_times[[title, city_slug]]
        create_showtimes_for_screen(movie, screen, times)
      end
    end
  end

  def city_screens(city_slug)
    city_name = city_label(city_slug)
    Screen.joins(:theater).where(theaters: { city: city_name }).to_a
  end

  def create_showtimes_for_screen(movie, screen, raw_times)
    time_slots = normalize_time_slots(raw_times)
    3.times do |day_offset|
      day = Date.current + day_offset.days
      time_slots.each do |slot|
        start_time = parse_slot_time(day, slot)
        next if start_time.blank? || start_time <= Time.current

        Showtime.create!(
          movie: movie,
          theater_id: screen.theater_id,
          screen: screen,
          start_time: start_time,
          end_time: start_time + movie.duration.minutes,
          price: [180, 220, 260, 300].sample
        )
      end
    end
  end

  def normalize_time_slots(raw_times)
    slots = Array(raw_times).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    return %w[10:00 13:30 17:00 20:30] if slots.empty?

    slots.first(5)
  end

  def parse_slot_time(day, slot)
    Time.zone.parse("#{day} #{slot}")
  rescue StandardError
    nil
  end

  def city_cache_path(city_slug)
    Rails.root.join('tmp', "serpapi_#{city_slug}.json")
  end

  def city_refresh_stamp_path(city_slug)
    Rails.root.join('tmp', "serpapi_#{city_slug}.stamp")
  end

  def read_city_cache(city_slug)
    path = city_cache_path(city_slug)
    return {} unless path.exist?

    JSON.parse(File.read(path))
  rescue StandardError
    {}
  end

  def write_city_cache(city_slug, payload)
    File.write(city_cache_path(city_slug), JSON.dump(payload))
  rescue StandardError
    nil
  end

  def write_city_refresh_stamp(city_slug)
    File.write(city_refresh_stamp_path(city_slug), Time.now.utc.iso8601)
  rescue StandardError
    nil
  end

  def cache_fresh?(city_slug)
    path = city_cache_path(city_slug)
    return false unless path.exist?
    return true if @cache_ttl_hours <= 0

    path.mtime >= @cache_ttl_hours.hours.ago
  rescue StandardError
    false
  end

  def cooldown_active?(city_slug)
    stamp = city_refresh_stamp_path(city_slug)
    return false unless stamp.exist?
    return false if @refresh_cooldown_minutes <= 0

    stamp.mtime >= @refresh_cooldown_minutes.minutes.ago
  rescue StandardError
    false
  end

  def city_label(city_slug)
    CITY_LABELS[city_slug] || city_slug.split('-').map(&:capitalize).join(' ')
  end
end
