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
    if poster_url.present? && (poster_url.start_with?('http') || poster_url.start_with?('/'))
      # Upgrade OMDB thumbnail to full-size poster
      return poster_url.gsub(/_SX\d+/, '_SX600').gsub(/_SY\d+/, '_SY900')
    end

    title_clean = title.gsub(/[^a-zA-Z0-9\s]/, '').strip
    "https://placehold.co/300x450/1a1a2e/e31e24?text=#{ERB::Util.url_encode(title_clean)}&font=montserrat"
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

  def youtube_embed_url
    return nil if youtube_video_id.blank?

    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  def display_genre
    return nil if genre.blank?
    return genre unless genre.include?('genre_name')

    names = genre.scan(/genre_name\"=>\"([^\"]+)\"/).flatten.uniq
    names.any? ? names.join(', ') : genre
  end
end
