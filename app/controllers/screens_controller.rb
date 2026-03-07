class ScreensController < ApplicationController
  def show
    @screen = Screen.find(params[:id])
    @theater = @screen.theater
    @showtimes = @screen.showtimes.includes(:movie).where('start_time > ?', Time.current).order(:start_time)
  end
end
