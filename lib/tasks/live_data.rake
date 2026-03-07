namespace :live_data do
  desc 'Sync live movies currently running in Indian theaters'
  task sync_movies: :environment do
    source = ENV.fetch('LIVE_MOVIE_SOURCE', 'serpapi')

    begin
      case source
      when 'serpapi'
        SerpapiSyncService.sync!
        puts "Synced #{Movie.count} live movies from SerpAPI."
      when 'tmdb'
        LiveMovieSyncService.sync!
        puts "Synced #{Movie.count} live movies from TMDB."
      when 'offline_india'
        OfflineIndiaSyncService.sync!
        puts "Synced #{Movie.count} movies from offline India catalog."
      else
        if ENV['BMS_COOKIE'].present? ||
           ENV['BMS_HTML_PATH'].present? ||
           ENV['BMS_HTML_GLOB'].present? ||
           Dir.glob(Rails.root.join('tmp', 'bookmyshow_*.html').to_s).any? ||
           Dir.glob(Rails.root.join('tmp', 'bookmyshow_cache_*.json').to_s).any?
          BookMyShowSyncService.sync!
          puts "Synced #{Movie.count} live movies from BookMyShow scraping."
        else
          OfflineIndiaSyncService.sync!
          puts "BookMyShow source not configured. Synced #{Movie.count} movies from offline India catalog."
        end
      end
    rescue StandardError => e
      puts "Primary sync failed: #{e.message}"
      if Movie.exists? && Showtime.where('start_time > ?', Time.current).exists?
        puts "Kept previous live catalog (movies=#{Movie.count}, upcoming_showtimes=#{Showtime.where('start_time > ?', Time.current).count})."
      else
        OfflineIndiaSyncService.sync!
        puts "Fallback synced #{Movie.count} movies from offline India catalog."
      end
    end
  end
end
