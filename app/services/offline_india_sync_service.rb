require 'cgi'

class OfflineIndiaSyncService
  MOVIES = [
    {
      title: 'Chhaava',
      description: 'Historical action drama inspired by the life of Chhatrapati Sambhaji Maharaj.',
      duration: 160,
      release_date: Date.new(2025, 2, 14),
      genre: 'Action/Drama',
      rating: 'U/A',
      director: 'Laxman Utekar',
      cast: 'Vicky Kaushal, Rashmika Mandanna',
      language: 'Hindi',
      poster_url: '/posters/chhaava.jpg'
    },
    {
      title: 'L2: Empuraan',
      description: 'Political action thriller and sequel in the Lucifer franchise.',
      duration: 170,
      release_date: Date.new(2025, 3, 27),
      genre: 'Action/Thriller',
      rating: 'U/A',
      director: 'Prithviraj Sukumaran',
      cast: 'Mohanlal, Prithviraj Sukumaran',
      language: 'Malayalam',
      poster_url: '/posters/l2_empuraan.jpg'
    },
    {
      title: 'Sikandar',
      description: 'Commercial action entertainer featuring a larger-than-life lead.',
      duration: 150,
      release_date: Date.new(2025, 3, 30),
      genre: 'Action',
      rating: 'U/A',
      director: 'A.R. Murugadoss',
      cast: 'Salman Khan',
      language: 'Hindi',
      poster_url: '/posters/sikandar.jpg'
    },
    {
      title: 'Coolie',
      description: 'Action drama centered on a powerful character-driven conflict.',
      duration: 155,
      release_date: Date.new(2025, 5, 1),
      genre: 'Action/Drama',
      rating: 'U/A',
      director: 'Lokesh Kanagaraj',
      cast: 'Rajinikanth',
      language: 'Tamil',
      poster_url: '/posters/coolie.jpg'
    },
    {
      title: 'War 2',
      description: 'Spy action sequel with global-scale set pieces.',
      duration: 165,
      release_date: Date.new(2025, 8, 14),
      genre: 'Action/Thriller',
      rating: 'U/A',
      director: 'Ayan Mukerji',
      cast: 'Hrithik Roshan, N. T. Rama Rao Jr.',
      language: 'Hindi',
      poster_url: '/posters/war_2.jpg'
    },
    {
      title: 'OG',
      description: 'Stylized gangster action drama.',
      duration: 150,
      release_date: Date.new(2025, 9, 27),
      genre: 'Action/Crime',
      rating: 'A',
      director: 'Sujeeth',
      cast: 'Pawan Kalyan',
      language: 'Telugu',
      poster_url: '/posters/og.jpg'
    },
    {
      title: 'Kantara: Chapter 1',
      description: 'Mythic-period action drama from the Kantara universe.',
      duration: 160,
      release_date: Date.new(2025, 10, 2),
      genre: 'Action/Fantasy',
      rating: 'U/A',
      director: 'Rishab Shetty',
      cast: 'Rishab Shetty',
      language: 'Kannada',
      poster_url: '/posters/kantara_chapter_1.jpg'
    },
    {
      title: 'Thug Life',
      description: 'Crime drama by a veteran actor-director collaboration.',
      duration: 158,
      release_date: Date.new(2025, 6, 5),
      genre: 'Crime/Drama',
      rating: 'U/A',
      director: 'Mani Ratnam',
      cast: 'Kamal Haasan',
      language: 'Tamil',
      poster_url: '/posters/thug_life.jpg'
    }
  ].freeze

  def self.sync!
    new.sync!
  end

  def sync!
    seen_titles = []

    MOVIES.each do |attrs|
      movie = Movie.find_or_initialize_by(title: attrs[:title])
      movie.assign_attributes(
        description: attrs[:description],
        duration: attrs[:duration],
        release_date: attrs[:release_date],
        genre: attrs[:genre],
        rating: attrs[:rating],
        director: attrs[:director],
        cast: attrs[:cast],
        language: attrs[:language],
        poster_url: attrs[:poster_url],
        trailer_url: movie.trailer_url.presence || youtube_search_url(attrs[:title])
      )
      movie.save!
      seen_titles << movie.title
    end

    cleanup_stale_movies(seen_titles)
    generate_upcoming_showtimes
  end

  private

  def cleanup_stale_movies(seen_titles)
    Movie.where.not(title: seen_titles).destroy_all
  end

  def generate_upcoming_showtimes
    return if Screen.count.zero?

    Movie.find_each do |movie|
      next if movie.showtimes.where('start_time > ?', Time.current).exists?

      screens = Screen.order('RANDOM()').limit(5).to_a
      screens.each do |screen|
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
    end
  end

  def youtube_search_url(title)
    query = CGI.escape("#{title} official trailer")
    "https://www.youtube.com/results?search_query=#{query}"
  end
end
