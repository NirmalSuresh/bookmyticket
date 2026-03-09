require 'cgi'

class Movie < ApplicationRecord
  has_many :showtimes, dependent: :destroy
  
  validates :title, presence: true
  validates :description, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :rating, inclusion: { in: %w[U U/A PG PG-13 A R], allow_blank: true }
  validates :language, presence: true
  
  scope :now_showing, -> { where('release_date <= ?', Date.current) }
  scope :coming_soon, -> { where('release_date > ?', Date.current) }
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }
  
  def self.genres
    pluck(:genre).uniq.compact
  end

  def poster_image_url
    return poster_url if poster_url.present?

    # Use data URI fallback for production compatibility
    fallback_poster_data_uri
  end

  def youtube_video_id
    return nil if trailer_url.blank?

    uri = URI.parse(trailer_url)
    host = uri.host.to_s.downcase

    if host.include?('youtu.be')
      uri.path.delete_prefix('/').split('/').first
    elsif host.include?('youtube.com')
      Rack::Utils.parse_query(uri.query)['v']
    end
  rescue URI::InvalidURIError
    nil
  end

  def youtube_trailer_url
    return nil if youtube_video_id.blank?

    "https://www.youtube.com/watch?v=#{youtube_video_id}"
  end

  def display_genre
    return nil if genre.blank?
    return genre unless genre.include?('genre_name')

    names = genre.scan(/genre_name\"=>\"([^\"]+)\"/).flatten.uniq
    names.any? ? names.join(', ') : genre
  end

  private

  def fallback_poster_data_uri
    title_text = ERB::Util.html_escape(title.to_s.first(28))
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="300" height="450" viewBox="0 0 300 450">
        <rect width="300" height="450" fill="#1f2937"/>
        <rect x="18" y="18" width="264" height="414" rx="12" fill="#111827" stroke="#374151"/>
        <text x="150" y="210" text-anchor="middle" fill="#f9fafb" font-family="Arial, sans-serif" font-size="16" font-weight="700">Poster Unavailable</text>
        <text x="150" y="240" text-anchor="middle" fill="#9ca3af" font-family="Arial, sans-serif" font-size="13">#{title_text}</text>
      </svg>
    SVG

    "data:image/svg+xml;utf8,#{CGI.escape(svg)}"
  end
end
