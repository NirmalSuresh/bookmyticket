require 'json'
require 'net/http'

class LiveMovieSyncService
  TMDB_BASE_URL = 'https://api.themoviedb.org/3'.freeze
  TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p/w500'.freeze

  def self.sync!(pages: 2)
    new(pages: pages).sync!
  end

  def initialize(pages: 2)
    @pages = pages
    @api_key = ENV['TMDB_API_KEY']
    @seen_titles = []
  end

  def sync!
    raise 'TMDB_API_KEY is missing' if @api_key.blank?

    tmdb_now_playing_movies.each do |movie_summary|
      details = fetch_json("/movie/#{movie_summary['id']}", append_to_response: 'videos,credits', language: 'en-US')
      upsert_movie(details)
    end

    cleanup_stale_movies
    generate_upcoming_showtimes
  end

  private

  def tmdb_now_playing_movies
    results = []
    (1..@pages).each do |page|
      payload = fetch_json('/movie/now_playing', region: 'IN', page: page, language: 'en-US')
      results.concat(payload.fetch('results', []))
    end
    results.uniq { |movie| movie['id'] }
  end

  def upsert_movie(details)
    title = details['title'].to_s.strip
    return if title.blank?

    attrs = {
      description: details['overview'].presence || "#{title} is currently running in Indian theaters.",
      duration: details['runtime'].to_i.positive? ? details['runtime'].to_i : 120,
      release_date: parse_release_date(details['release_date']),
      genre: Array(details['genres']).map { |genre| genre['name'] }.reject(&:blank?).join('/'),
      rating: nil,
      language: resolve_language(details),
      poster_url: resolve_poster_url(details['poster_path']),
      trailer_url: resolve_trailer_url(details),
      cast: resolve_cast(details),
      director: resolve_director(details)
    }

    movie = Movie.find_or_initialize_by(title: title)
    movie.assign_attributes(attrs)
    movie.save!
    @seen_titles << title
  end

  def cleanup_stale_movies
    Movie.where.not(title: @seen_titles).destroy_all
  end

  def generate_upcoming_showtimes
    return if Screen.count.zero?

    Movie.find_each do |movie|
      next if movie.showtimes.where('start_time > ?', Time.current).exists?

      Screen.order('RANDOM()').limit(5).each do |screen|
        create_showtimes_for_screen(movie, screen)
      end
    end
  end

  def create_showtimes_for_screen(movie, screen)
    time_slots = %w[09:30 13:00 16:30 20:00]
    5.times do |day_offset|
      day = Date.current + day_offset.days
      time_slots.each do |slot|
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

  def resolve_poster_url(poster_path)
    return nil if poster_path.blank?

    "#{TMDB_IMAGE_BASE_URL}#{poster_path}"
  end

  def resolve_language(details)
    spoken = Array(details['spoken_languages']).first
    spoken&.fetch('english_name', nil).presence || details['original_language'].to_s.upcase.presence || 'Hindi'
  end

  def resolve_trailer_url(details)
    videos = Array(details.dig('videos', 'results'))
    youtube_trailer = videos.find do |video|
      video['site'] == 'YouTube' && video['type'] == 'Trailer' && video['key'].present?
    end
    return nil if youtube_trailer.blank?

    "https://www.youtube.com/watch?v=#{youtube_trailer['key']}"
  end

  def resolve_cast(details)
    cast = Array(details.dig('credits', 'cast')).first(5).map { |member| member['name'] }.reject(&:blank?)
    cast.join(', ')
  end

  def resolve_director(details)
    Array(details.dig('credits', 'crew')).find { |member| member['job'] == 'Director' }&.fetch('name', nil)
  end

  def parse_release_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def fetch_json(path, params = {})
    uri = URI("#{TMDB_BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params.merge(api_key: @api_key))
    response = Net::HTTP.get_response(uri)
    raise "TMDB request failed: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise "TMDB response parse error: #{e.message}"
  end
end
