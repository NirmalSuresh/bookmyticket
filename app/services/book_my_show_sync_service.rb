require 'cgi'
require 'json'
require 'net/http'
require 'set'

class BookMyShowSyncService
  DEFAULT_CITIES = %w[
    mumbai
    bengaluru
    national-capital-region-ncr
    chennai
    kolkata
    hyderabad
    pune
  ].freeze

  ALL_INDIA_CITIES = %w[
    mumbai
    national-capital-region-ncr
    bengaluru
    hyderabad
    chennai
    kolkata
    pune
    ahmedabad
    kochi
    chandigarh
    jaipur
    lucknow
    bhubaneswar
    indore
    surat
    nagpur
    patna
    coimbatore
    vadodara
    visakhapatnam
    vijayawada
    mysuru
    nashik
    raipur
    guwahati
    bhopal
    trivandrum
    madurai
    warangal
    noida
    gurgaon
    faridabad
  ].freeze

  CITY_ALIASES = {
    'bangalore' => 'bengaluru',
    'bengaluru' => 'bengaluru',
    'delhi' => 'national-capital-region-ncr',
    'delhi-ncr' => 'national-capital-region-ncr',
    'ncr' => 'national-capital-region-ncr',
    'new-delhi' => 'national-capital-region-ncr',
    'national-capital-region-ncr' => 'national-capital-region-ncr'
  }.freeze

  CITY_LABELS = {
    'mumbai' => 'Mumbai',
    'bengaluru' => 'Bengaluru',
    'national-capital-region-ncr' => 'Delhi-NCR',
    'chennai' => 'Chennai',
    'kolkata' => 'Kolkata',
    'hyderabad' => 'Hyderabad',
    'pune' => 'Pune',
    'ahmedabad' => 'Ahmedabad',
    'kochi' => 'Kochi',
    'chandigarh' => 'Chandigarh',
    'jaipur' => 'Jaipur',
    'lucknow' => 'Lucknow',
    'bhubaneswar' => 'Bhubaneswar',
    'indore' => 'Indore',
    'surat' => 'Surat',
    'nagpur' => 'Nagpur',
    'patna' => 'Patna',
    'coimbatore' => 'Coimbatore',
    'vadodara' => 'Vadodara',
    'visakhapatnam' => 'Visakhapatnam',
    'vijayawada' => 'Vijayawada',
    'mysuru' => 'Mysuru',
    'nashik' => 'Nashik',
    'raipur' => 'Raipur',
    'guwahati' => 'Guwahati',
    'bhopal' => 'Bhopal',
    'trivandrum' => 'Thiruvananthapuram',
    'madurai' => 'Madurai',
    'warangal' => 'Warangal',
    'noida' => 'Noida',
    'gurgaon' => 'Gurgaon',
    'faridabad' => 'Faridabad'
  }.freeze

  def self.sync!
    new.sync!
  end

  def initialize
    raw_cities = ENV.fetch('BMS_CITIES', DEFAULT_CITIES.join(',')).to_s.strip
    @city_slugs = if raw_cities.casecmp('all_india').zero?
      ALL_INDIA_CITIES
    else
      raw_cities.split(',').map { |city| canonical_city_slug(city) }.compact.uniq
    end

    @seen_titles = []
    @movie_cities = Hash.new { |h, k| h[k] = Set.new }
    @detail_cache = {}
    @omdb_cache = {}
    @omdb_api_key = ENV['OMDB_API_KEY'].to_s.strip
    @max_movie_age_days = ENV.fetch('BMS_MAX_MOVIE_AGE_DAYS', '180').to_i
    @cache_max_hours = ENV.fetch('BMS_CACHE_MAX_HOURS', '18').to_i
  end

  def sync!
    city_to_movies = movie_data_by_city
    total_records = city_to_movies.values.flatten.size
    raise 'No movie titles found from BookMyShow source.' if total_records.zero?

    city_to_movies.each do |city_slug, movie_records|
      movie_records.each do |record|
        title = clean_title(record[:title])
        next if title.blank?

        movie = upsert_movie(record.merge(title: title))
        @movie_cities[movie.title] << city_slug if movie
      end
    end

    target_cities = city_to_movies.keys
    ensure_city_inventory!(target_cities)
    reset_future_showtimes(target_cities)
    generate_upcoming_showtimes
  end

  private

  def movie_data_by_city
    mapping = {}

    if ENV['BMS_JSON_GLOB'].present?
      Dir.glob(ENV['BMS_JSON_GLOB']).sort.each do |path|
        city_slug = canonical_city_slug(File.basename(path)[/bookmyshow_([a-z\-]+)\.json/i, 1])
        next if city_slug.blank?

        records = parse_json_snapshot(path)
        mapping[city_slug] = records if records.any?
      end
      return mapping if mapping.any?
    end

    if ENV['BMS_JSON_PATH'].present?
      path = ENV['BMS_JSON_PATH']
      city_slug = canonical_city_slug(File.basename(path)[/bookmyshow_([a-z\-]+)\.json/i, 1])
      records = parse_json_snapshot(path)
      return { city_slug => records } if city_slug.present? && records.any?
    end

    if ENV['BMS_COOKIE'].present?
      @city_slugs.each do |city_slug|
        begin
          html = fetch_city_movies_html(city_slug)
          records = extract_movie_records(html)
          if records.any?
            mapping[city_slug] = records
            write_city_cache(city_slug, records)
          end
        rescue StandardError => e
          Rails.logger.warn("BookMyShow city fetch skipped for #{city_slug}: #{e.message}")
          cached = read_city_cache(city_slug)
          mapping[city_slug] = cached if cached.any?
        end
      end

      return mapping if mapping.any?
    end

    if ENV['BMS_HTML_GLOB'].present?
      Dir.glob(ENV['BMS_HTML_GLOB']).sort.each do |path|
        html = File.read(path)
        city_slug = city_from_html(html) || city_from_path(path)
        next if city_slug.blank?

        records = extract_movie_records(html)
        if records.any?
          mapping[city_slug] = records
          write_city_cache(city_slug, records)
        end
      end
      return mapping if mapping.any?
    end

    local_files = Dir.glob(Rails.root.join('tmp', 'bookmyshow_*.html').to_s).sort
    if local_files.any?
      local_files.each do |path|
        html = File.read(path)
        city_slug = city_from_html(html) || city_from_path(path)
        next if city_slug.blank?

        records = extract_movie_records(html)
        if records.any?
          mapping[city_slug] = records
          write_city_cache(city_slug, records)
        end
      end
      return mapping if mapping.any?
    end

    if ENV['BMS_HTML_PATH'].present?
      html = File.read(ENV['BMS_HTML_PATH'])
      city_slug = city_from_html(html) || city_from_path(ENV['BMS_HTML_PATH'])
      records = extract_movie_records(html)
      if city_slug.present? && records.any?
        write_city_cache(city_slug, records)
        return { city_slug => records }
      end
    end

    @city_slugs.each do |city_slug|
      cached = read_city_cache(city_slug)
      mapping[city_slug] = cached if cached.any?
    end

    mapping
  end

  def parse_json_snapshot(path)
    raw = JSON.parse(File.read(path))
    rows = raw.is_a?(Array) ? raw : []
    rows.filter_map do |row|
      next unless row.is_a?(Hash)
      title = clean_title(row['title'] || row[:title])
      next if title.blank?

      {
        title: title,
        poster_url: row['poster_url'] || row[:poster_url],
        listing_url: row['listing_url'] || row[:listing_url],
        rating: row['rating'] || row[:rating],
        language: row['language'] || row[:language],
        genre: row['genre'] || row[:genre],
        description: row['description'] || row[:description],
        release_date: row['release_date'] || row[:release_date],
        cast: row['cast'] || row[:cast],
        director: row['director'] || row[:director],
        trailer_url: row['trailer_url'] || row[:trailer_url]
      }
    end
  rescue JSON::ParserError
    []
  end

  def fetch_city_movies_html(city_slug)
    url = ENV.fetch('BMS_CITY_URL_TEMPLATE', 'https://in.bookmyshow.com/explore/movies-%{city}')
    uri = URI(format(url, city: city_slug))

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = ENV.fetch('BMS_USER_AGENT', default_user_agent)
    request['Accept'] = 'text/html,application/xhtml+xml'
    request['Accept-Language'] = 'en-IN,en;q=0.9'
    request['Cookie'] = ENV['BMS_COOKIE'] if ENV['BMS_COOKIE'].present?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    html = response.body.to_s

    if response.code.to_i >= 400 || html.include?('Attention Required! | Cloudflare') || html.include?('Sorry, you have been blocked')
      raise "BookMyShow blocked request for #{city_slug}. Set BMS_COOKIE or local HTML source."
    end

    html
  end

  def extract_movie_records(html)
    records = extract_from_initial_state(html)
    return records if records.any?

    records = extract_from_item_list_ld_json(html)
    return records if records.any?

    extract_titles(html).map { |title| { title: title } }
  end

  def extract_from_item_list_ld_json(html)
    html.scan(/\"@type\":\"ListItem\",\"image\":\"([^\"]+)\".*?\"url\":\"([^\"]+)\".*?\"name\":\"([^\"]+)\"/m).map do |image, url, name|
      {
        title: clean_title(name),
        poster_url: image,
        listing_url: url
      }
    end
  end

  def extract_from_initial_state(html)
    state = parse_initial_state(html)
    return [] if state.blank?

    widgets = state.dig('explore', 'movies', 'listings')
    return [] unless widgets.is_a?(Array)

    widgets.flat_map { |widget| Array(widget['cards']) }
           .filter_map do |card|
      title = card.dig('text', 0, 'components', 0, 'text') || card['seoText']
      next if title.blank?

      {
        title: clean_title(title),
        poster_url: card.dig('image', 'url'),
        listing_url: card['ctaUrl'],
        rating: card.dig('text', 1, 'components', 0, 'text'),
        language: card.dig('text', 2, 'components', 0, 'text'),
        genre: card.dig('analytics', 'genre')
      }
    end
  end

  def parse_initial_state(html)
    match = html.match(/window\.__INITIAL_STATE__\s*=\s*(\{.*?\})<\/script>/m)
    return nil unless match

    JSON.parse(match[1])
  rescue JSON::ParserError
    nil
  end

  def extract_titles(html)
    titles = []
    titles.concat(html.scan(/"@type":"Movie","name":"([^"]+)"/).flatten)
    titles.concat(html.scan(/"@type":"ListItem"[^}]*"name":"([^"]+)"/).flatten)
    titles.concat(html.scan(/"url":"https:\/\/in\.bookmyshow\.com\/[^"]+\/movies\/[^"]+\/[^"]+","name":"([^"]+)"/).flatten)
    titles.map { |title| clean_title(title) }.reject(&:blank?).uniq
  end

  def upsert_movie(record)
    title = record[:title]
    attrs = default_movie_attributes(title, record)
    detail = detail_for(record[:listing_url])
    merge_detail_attributes!(attrs, detail) if detail
    omdb = omdb_for(title)
    merge_omdb_attributes!(attrs, omdb) if omdb

    release_date = attrs[:release_date]
    return nil unless recent_release?(release_date)

    movie = Movie.find_or_initialize_by(title: title)
    attrs[:description] ||= movie.description.presence || 'Synopsis currently unavailable from source.'
    attrs[:poster_url] ||= movie.poster_url
    attrs[:genre] ||= movie.genre || 'Drama'
    attrs[:language] ||= movie.language || 'Hindi'
    attrs[:rating] ||= movie.rating
    attrs[:duration] ||= movie.duration || 130
    attrs[:release_date] ||= movie.release_date || Date.current
    attrs[:cast] ||= movie.cast
    attrs[:director] ||= movie.director
    movie.assign_attributes(attrs)
    movie.save!
    @seen_titles << movie.title
    movie
  end

  def default_movie_attributes(title, record)
    {
      description: record[:description].presence || "Synopsis currently unavailable from source.",
      duration: 130,
      release_date: parse_release_date(record[:release_date]),
      genre: normalize_genre(record[:genre]) || 'Drama',
      rating: normalize_rating(record[:rating]),
      language: normalize_language(record[:language]) || 'Hindi',
      poster_url: normalized_poster_url(record[:poster_url]),
      trailer_url: record[:trailer_url].presence || youtube_search_url(title),
      cast: clean_title(record[:cast].to_s).presence,
      director: clean_title(record[:director].to_s).presence
    }
  end

  def detail_for(listing_url)
    return nil if listing_url.blank?

    @detail_cache[listing_url] ||= begin
      html = fetch_movie_detail_html(listing_url)
      parse_movie_ld_json(html)
    rescue StandardError => e
      Rails.logger.warn("BookMyShow detail fetch skipped for #{listing_url}: #{e.message}")
      nil
    end
  end

  def fetch_movie_detail_html(listing_url)
    uri = if listing_url.start_with?('http://', 'https://')
      URI(listing_url)
    else
      URI.join('https://in.bookmyshow.com', listing_url)
    end

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = ENV.fetch('BMS_USER_AGENT', default_user_agent)
    request['Accept'] = 'text/html,application/xhtml+xml'
    request['Accept-Language'] = 'en-IN,en;q=0.9'
    request['Cookie'] = ENV['BMS_COOKIE'] if ENV['BMS_COOKIE'].present?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    html = response.body.to_s

    if response.code.to_i >= 400 || html.include?('Attention Required! | Cloudflare') || html.include?('Sorry, you have been blocked')
      raise 'detail page blocked'
    end

    html
  end

  def parse_movie_ld_json(html)
    scripts = html.scan(%r{<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>}m).flatten
    return nil if scripts.empty?

    objects = scripts.flat_map do |raw|
      begin
        parsed = JSON.parse(raw)
        parsed.is_a?(Array) ? parsed : [parsed]
      rescue JSON::ParserError
        []
      end
    end

    movie_obj = objects.find do |obj|
      type = obj.is_a?(Hash) ? obj['@type'] : nil
      type == 'Movie' || (type.is_a?(Array) && type.include?('Movie'))
    end
    return nil unless movie_obj.is_a?(Hash)

    {
      description: movie_obj['description'].to_s.strip.presence,
      poster_url: normalize_ld_image(movie_obj['image']),
      genre: normalize_ld_genre(movie_obj['genre']),
      release_date: parse_release_date(movie_obj['datePublished'] || movie_obj['dateCreated'] || movie_obj['releaseDate']),
      duration: parse_iso_duration(movie_obj['duration']),
      director: extract_names(movie_obj['director']),
      cast: extract_names(movie_obj['actor']),
      trailer_url: movie_obj.dig('trailer', 'url').to_s.strip.presence,
      language: normalize_language(movie_obj['inLanguage']),
      rating: normalize_rating(movie_obj['contentRating'])
    }
  end

  def merge_detail_attributes!(attrs, detail)
    attrs[:description] = detail[:description] if detail[:description].present?
    attrs[:poster_url] = detail[:poster_url] if detail[:poster_url].present?
    attrs[:genre] = detail[:genre] if detail[:genre].present?
    attrs[:release_date] = detail[:release_date] if detail[:release_date].present?
    attrs[:duration] = detail[:duration] if detail[:duration].present?
    attrs[:director] = detail[:director] if detail[:director].present?
    attrs[:cast] = detail[:cast] if detail[:cast].present?
    attrs[:language] = detail[:language] if detail[:language].present?
    attrs[:rating] = detail[:rating] if detail[:rating].present?
    attrs[:trailer_url] = detail[:trailer_url] if detail[:trailer_url].present?
  end

  def merge_omdb_attributes!(attrs, omdb)
    attrs[:poster_url] = normalized_poster_url(omdb['Poster']) if attrs[:poster_url].blank?
    attrs[:description] = clean_title(omdb['Plot']) if attrs[:description].blank? || attrs[:description].include?('currently unavailable')
    attrs[:genre] = normalize_genre(omdb['Genre']) if attrs[:genre].blank?
    attrs[:language] = normalize_language(omdb['Language']) if attrs[:language].blank?
    attrs[:director] = clean_title(omdb['Director']) if attrs[:director].blank?
    attrs[:cast] = clean_title(omdb['Actors']) if attrs[:cast].blank?
    attrs[:release_date] = parse_release_date(omdb['Released']) if attrs[:release_date].blank?

    runtime = omdb['Runtime'].to_s[/\d+/]&.to_i
    attrs[:duration] = runtime if attrs[:duration].blank? && runtime.to_i.positive?
  end

  def normalize_ld_image(value)
    case value
    when String
      normalized_poster_url(value)
    when Array
      normalized_poster_url(value.first)
    when Hash
      normalized_poster_url(value['url'])
    end
  end

  def normalize_ld_genre(value)
    case value
    when String
      value.presence
    when Array
      value.compact.join('/').presence
    end
  end

  def extract_names(value)
    items = Array(value)
    names = items.filter_map do |item|
      case item
      when Hash then item['name']
      when String then item
      end
    end
    names = names.map { |name| clean_title(name) }.reject(&:blank?)
    names.any? ? names.join(', ') : nil
  end

  def normalize_genre(value)
    clean_title(value.to_s.tr('|', '/')).presence
  end

  def normalize_language(value)
    case value
    when Array
      clean_title(value.first.to_s)
    else
      clean_title(value.to_s.split(',').first.to_s)
    end.presence
  end

  def normalized_poster_url(url)
    return nil if url.blank? || url == 'N/A'
    cleaned = url.to_s.strip
    return "https:#{cleaned}" if cleaned.start_with?('//')
    return "https://in.bookmyshow.com#{cleaned}" if cleaned.start_with?('/')

    cleaned
  end

  def normalize_rating(value)
    return nil if value.blank?

    raw = clean_title(value)
    map = {
      'U' => 'U',
      'UA' => 'U/A',
      'U/A' => 'U/A',
      'A' => 'A',
      'PG' => 'PG',
      'PG-13' => 'PG-13',
      'R' => 'R',
      'G' => 'U'
    }
    map[raw.upcase] || map[raw] || nil
  end

  def parse_release_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def parse_iso_duration(value)
    return nil if value.blank?

    iso = value.to_s
    hours = iso[/([0-9]+)H/, 1].to_i
    mins = iso[/([0-9]+)M/, 1].to_i
    total = (hours * 60) + mins
    total.positive? ? total : nil
  end

  def clean_title(value)
    CGI.unescapeHTML(value.to_s).gsub(/\s+/, ' ').strip
  end

  def youtube_search_url(title)
    "https://www.youtube.com/results?search_query=#{CGI.escape("#{title} official trailer")}" 
  end

  def reset_future_showtimes(city_slugs)
    city_names = city_slugs.map { |slug| city_label(slug) }.compact.uniq
    return if city_names.empty?

    theater_ids = Theater.where(city: city_names).pluck(:id)
    return if theater_ids.empty?

    Showtime.where(theater_id: theater_ids).where('start_time > ?', Time.current).delete_all
  end

  def generate_upcoming_showtimes
    target_cities = @movie_cities.values.flat_map(&:to_a).uniq
    ensure_city_inventory!(target_cities)

    Movie.where(title: @seen_titles).find_each do |movie|
      city_slugs = @movie_cities[movie.title].to_a
      city_slugs.each do |city_slug|
        screen = city_screens(city_slug).sample
        next unless screen

        create_showtimes_for_screen(movie, screen)
      end
    end
  end

  def ensure_city_inventory!(city_slugs)
    city_slugs.each do |city_slug|
      city_name = city_label(city_slug)
      next if city_name.blank?

      theater = Theater.find_or_create_by!(name: "PVR #{city_name}", city: city_name) do |t|
        t.location = "#{city_name} Central"
      end

      next if theater.screens.exists?

      Screen.create!(name: '1', capacity: 150, theater: theater)
      Screen.create!(name: '2', capacity: 120, theater: theater)
    end
  end

  def city_screens(city_slug)
    Screen.includes(:theater).to_a.select do |screen|
      canonical_city_slug(screen.theater&.city) == city_slug
    end
  end

  def create_showtimes_for_screen(movie, screen)
    %w[09:30 13:00 16:30 20:00].each do |slot|
      5.times do |day_offset|
        day = Date.current + day_offset.days
        start_time = Time.zone.parse("#{day} #{slot}")
        next if start_time <= Time.current

        Showtime.create!(
          movie: movie,
          theater_id: screen.theater_id,
          screen: screen,
          start_time: start_time,
          end_time: start_time + movie.duration.minutes,
          price: [180, 220, 260].sample
        )
      end
    end
  end

  def city_from_html(html)
    canonical = html.to_s[/<link rel="canonical" href="https:\/\/in\.bookmyshow\.com\/explore\/movies-([^"]+)"/, 1]
    canonical_city_slug(canonical)
  end

  def city_from_path(path)
    canonical_city_slug(File.basename(path).to_s[/bookmyshow_([a-z\-]+)\.html/i, 1])
  end

  def canonical_city_slug(value)
    raw = value.to_s.strip.downcase
    return nil if raw.blank?

    CITY_ALIASES.fetch(raw, raw)
  end

  def city_label(city_slug)
    CITY_LABELS[city_slug] || city_slug.to_s.split('-').map(&:capitalize).join(' ')
  end

  def default_user_agent
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
  end

  def city_cache_path(city_slug)
    Rails.root.join('tmp', "bookmyshow_cache_#{city_slug}.json")
  end

  def write_city_cache(city_slug, records)
    File.write(city_cache_path(city_slug), JSON.pretty_generate(records))
  rescue StandardError
    nil
  end

  def read_city_cache(city_slug)
    path = city_cache_path(city_slug)
    return [] unless File.exist?(path)
    return [] if @cache_max_hours.positive? && File.mtime(path) < @cache_max_hours.hours.ago

    parse_json_snapshot(path)
  rescue StandardError
    []
  end

  def omdb_for(title)
    return nil if @omdb_api_key.blank? || title.blank?

    @omdb_cache[title] ||= begin
      uri = URI('http://www.omdbapi.com/')
      uri.query = URI.encode_www_form({ t: title, apikey: @omdb_api_key })
      res = Net::HTTP.get_response(uri)
      unless res.is_a?(Net::HTTPSuccess)
        nil
      else
        json = JSON.parse(res.body)
        json['Response'] == 'True' ? json : nil
      end
    rescue StandardError
      nil
    end
  end

  def recent_release?(release_date)
    return true if @max_movie_age_days <= 0
    return true if release_date.blank?

    release_date >= @max_movie_age_days.days.ago.to_date
  end
end
