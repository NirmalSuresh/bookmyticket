class MovieSyncJob < ApplicationJob
  queue_as :default

  def perform
    source = ENV.fetch('LIVE_MOVIE_SOURCE', 'offline_india')
    
    case source
    when 'serpapi'
      return unless ENV['SERPAPI_KEY'].present?
      SerpapiSyncService.sync!
    when 'tmdb'
      return unless ENV['TMDB_API_KEY'].present?
      LiveMovieSyncService.sync!
    when 'bookmyshow'
      if bms_source_available?
        BookMyShowSyncService.sync!
      else
        OfflineIndiaSyncService.sync!
      end
    else
      OfflineIndiaSyncService.sync!
    end
    
    Rails.logger.info("Movie sync completed via #{source}")
  rescue StandardError => e
    Rails.logger.error("Background movie sync failed: #{e.message}")
    OfflineIndiaSyncService.sync!
    Rails.logger.info('Fallback: Loaded offline India catalog')
  end

  private

  def bms_source_available?
    return true if ENV['BMS_COOKIE'].present?
    return true if ENV['BMS_HTML_PATH'].present?
    return true if ENV['BMS_HTML_GLOB'].present?
    return true if Dir.glob(Rails.root.join('tmp', 'bookmyshow_cache_*.json').to_s).any?
    Dir.glob(Rails.root.join('tmp', 'bookmyshow_*.html').to_s).any?
  end
end
