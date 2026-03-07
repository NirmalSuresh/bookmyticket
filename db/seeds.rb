puts 'Resetting movie scheduling data...'
Booking.delete_all
Showtime.delete_all
Screen.delete_all
Theater.delete_all
Movie.delete_all

theaters = [
  { name: 'PVR Phoenix Marketcity', city: 'Bangalore', location: 'Bangalore - Whitefield' },
  { name: 'INOX Inorbit Mall', city: 'Mumbai', location: 'Mumbai - Malad' },
  { name: 'PVR Select Citywalk', city: 'Delhi', location: 'Delhi - Saket' },
  { name: 'PVR Express Avenue', city: 'Chennai', location: 'Chennai - Royapettah' },
  { name: 'INOX South City Mall', city: 'Kolkata', location: 'Kolkata - Prince Anwar Shah Road' }
]

created_theaters = Theater.create!(theaters)

screens = created_theaters.flat_map do |theater|
  [
    { name: '1', capacity: 160, theater_id: theater.id },
    { name: '2', capacity: 140, theater_id: theater.id },
    { name: '3', capacity: 120, theater_id: theater.id }
  ]
end

created_screens = Screen.create!(screens)

if ENV.fetch('LIVE_MOVIE_SOURCE', 'serpapi') == 'serpapi' && ENV['SERPAPI_KEY'].present?
  puts 'Syncing live Indian now-playing movies from SerpAPI...'
  SerpapiSyncService.sync!
elsif ENV.fetch('LIVE_MOVIE_SOURCE', 'serpapi') == 'tmdb' && ENV['TMDB_API_KEY'].present?
  puts 'Syncing live Indian now-playing movies from TMDB...'
  LiveMovieSyncService.sync!
elsif ENV.fetch('LIVE_MOVIE_SOURCE', 'serpapi') == 'offline_india'
  puts 'Syncing movies from offline India catalog...'
  OfflineIndiaSyncService.sync!
elsif ENV['BMS_HTML_PATH'].present? ||
      ENV['BMS_HTML_GLOB'].present? ||
      ENV['BMS_COOKIE'].present? ||
      Dir.glob(Rails.root.join('tmp', 'bookmyshow_*.html').to_s).any? ||
      Dir.glob(Rails.root.join('tmp', 'bookmyshow_cache_*.json').to_s).any?
  puts 'Syncing live Indian now-playing movies from BookMyShow scraping...'
  BookMyShowSyncService.sync!
else
  puts 'No SerpAPI/TMDB/BookMyShow source configured. Syncing offline India catalog.'
  OfflineIndiaSyncService.sync!
end

showtimes = []
if Showtime.count.zero?
  source_city = ENV['BMS_SOURCE_CITY'].to_s.strip.downcase
  eligible_screens = created_screens
  if source_city.present?
    scoped = created_screens.select { |screen| screen.theater.city.to_s.downcase == source_city }
    eligible_screens = scoped if scoped.any?
  end

  Movie.find_each do |movie|
    eligible_screens.sample([6, eligible_screens.count].min).each do |screen|
      5.times do |day_offset|
        day = Date.current + day_offset.days
        %w[09:30 13:00 16:30 20:00].each do |slot|
          start_time = Time.zone.parse("#{day} #{slot}")
          next if start_time <= Time.current

          showtimes << {
            movie_id: movie.id,
            theater_id: screen.theater_id,
            screen_id: screen.id,
            start_time: start_time,
            end_time: start_time + movie.duration.minutes,
            price: [180, 220, 260].sample
          }
        end
      end
    end
  end

  Showtime.create!(showtimes)
end

puts "Seed complete: #{Movie.count} movies, #{Theater.count} theaters, #{Screen.count} screens, #{Showtime.count} showtimes."
