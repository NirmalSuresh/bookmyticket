class Theater < ApplicationRecord
  has_many :screens, dependent: :destroy
  has_many :showtimes, through: :screens
  
  validates :name, presence: true
  validates :location, presence: true
  
  def total_capacity
    screens.sum(:capacity)
  end
  
  def upcoming_showtimes
    showtimes.where('start_time > ?', Time.current).includes(:movie)
  end
end
