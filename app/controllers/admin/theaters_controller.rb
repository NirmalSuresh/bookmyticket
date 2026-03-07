class Admin::TheatersController < ApplicationController
  before_action :set_theater, only: [:show, :edit, :update, :destroy]
  
  def index
    @theaters = Theater.all
  end
  
  def show
    @screens = @theater.screens.includes(:showtimes)
  end
  
  def new
    @theater = Theater.new
  end
  
  def create
    @theater = Theater.new(theater_params)
    if @theater.save
      redirect_to admin_theater_path(@theater), notice: 'Theater was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @theater.update(theater_params)
      redirect_to admin_theater_path(@theater), notice: 'Theater was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @theater.destroy
    redirect_to admin_theaters_path, notice: 'Theater was successfully deleted.'
  end
  
  private
  
  def set_theater
    @theater = Theater.find(params[:id])
  end
  
  def theater_params
    params.require(:theater).permit(:name, :location)
  end
end
