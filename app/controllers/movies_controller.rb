class MoviesController < ApplicationController
  def index
    sync_live_movies_if_needed

    @movies = Movie.joins(showtimes: :theater)
                   .where('showtimes.start_time > ?', Time.current)
    @movies = @movies.where(theaters: { city: current_city }) if current_city.present?
    @movies = @movies.distinct
    @movies = @movies.by_genre(params[:genre]) if params[:genre].present? && params[:genre] != 'All'
    @movies = @movies.limit(20) # Limit to prevent too many movies
  end

  def show
    @movie = Movie.find(params[:id])
    @showtimes = @movie.showtimes.includes(:theater, :screen)
                       .where('start_time > ?', Time.current)
    @showtimes = @showtimes.joins(:theater).where(theaters: { city: current_city }) if current_city.present?
    @showtimes = @showtimes.order(:start_time)
  end

  private

  def sync_live_movies_if_needed
    # Disable auto-sync on page load to prevent timeouts
    # Sync should be run manually or via background job
    return true if Movie.joins(:showtimes).where('showtimes.start_time > ?', Time.current).exists?
    
    # Only use fallback if no movies exist at all
    OfflineIndiaSyncService.sync!
    Rails.logger.info('No movies found - loaded offline India fallback')
  end

  def bms_source_available?
    return true if ENV['BMS_COOKIE'].present?
    return true if ENV['BMS_HTML_PATH'].present?
    return true if ENV['BMS_HTML_GLOB'].present?
    return true if Dir.glob(Rails.root.join('tmp', 'bookmyshow_cache_*.json').to_s).any?

    Dir.glob(Rails.root.join('tmp', 'bookmyshow_*.html').to_s).any?
  end
end
