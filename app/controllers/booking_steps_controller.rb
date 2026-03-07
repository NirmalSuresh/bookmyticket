class BookingStepsController < ApplicationController
  before_action :set_movie

  def city
    @movie = Movie.find(params[:movie_id])
    @cities = @movie.showtimes
                    .joins(:theater)
                    .where('showtimes.start_time > ?', Time.current)
                    .where.not(theaters: { city: [nil, ""] })
                    .distinct
                    .order('theaters.city')
                    .pluck('theaters.city')
    if @cities.empty?
      @cities = Theater.distinct.pluck(:location).map { |loc| loc.to_s.split(' - ').first }.reject(&:blank?).uniq.sort
    end

    if current_city.present? && @cities.include?(current_city)
      session[:booking_city] = current_city
      redirect_to "/book/#{@movie.id}/theater?city=#{CGI.escape(current_city)}"
      return
    end

    session[:booking_city] = nil
    session[:booking_theater_id] = nil
    session[:booking_date] = nil
    session[:booking_showtime_id] = nil
  end

  def theater
    city = params[:city].presence || current_city
    session[:booking_city] = city
    @theaters = Theater.joins(:showtimes)
                       .where(city: city, showtimes: { movie_id: @movie.id })
                       .where('showtimes.start_time > ?', Time.current)
                       .distinct
  end

  def date
    theater_id = params[:theater_id]
    session[:booking_theater_id] = theater_id
    @theater = Theater.find(theater_id)

    @available_dates = @theater.showtimes
                              .where(movie: @movie)
                              .where('start_time > ?', Time.current)
                              .where(start_time: Time.current..7.days.from_now.end_of_day)
                              .order(:start_time)
                              .pluck(:start_time)
                              .map(&:to_date)
                              .uniq
  end

  def time
    date_str = params[:date]
    session[:booking_date] = date_str
    @theater = Theater.find_by(id: session[:booking_theater_id])
    unless @theater
      redirect_to book_movie_path(@movie), alert: 'Please select a theater first.'
      return
    end

    date = begin
      Date.parse(date_str)
    rescue ArgumentError, TypeError
      Date.current
    end

    @showtimes = @theater.showtimes
                    .where(movie: @movie)
                    .where('DATE(start_time) = ?', date)
                    .includes(:screen)
                    .order(:start_time)
  end

  private

  def set_movie
    @movie = Movie.find(params[:movie_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movies_path, alert: 'Movie not found. Please select a movie from the list.'
  end
end
