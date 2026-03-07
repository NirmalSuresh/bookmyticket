class Showtime < ApplicationRecord
  belongs_to :movie
  belongs_to :theater
  belongs_to :screen
  has_many :bookings, dependent: :destroy
  
  validates :movie, presence: true
  validates :theater, presence: true
  validates :screen, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  
  validate :end_time_after_start_time
  validate :screen_belongs_to_theater
  
  scope :upcoming, -> { where('start_time > ?', Time.current) }
  scope :for_movie, ->(movie) { where(movie: movie) }
  
  def available_seats
    screen.available_seats(self)
  end
  
  def booked_seats
    bookings.where(status: 'confirmed').flat_map { |booking| booking.seats || [] }
  end
  
  def seats_available?(seat_list)
    (seat_list - available_seats).empty?
  end
  
  private
  
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
  
  def screen_belongs_to_theater
    return if screen.blank? || theater.blank?
    
    unless screen.theater_id == theater_id
      errors.add(:screen, "must belong to the same theater")
    end
  end
end
