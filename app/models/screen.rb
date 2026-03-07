class Screen < ApplicationRecord
  belongs_to :theater
  has_many :showtimes, dependent: :destroy
  
  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  
  def seat_layout
    # Generate a default seat layout (rows A-O, columns 1-10)
    rows = ('A'..('A'.ord + [capacity / 10, 14].min - 1).chr).to_a
    seats_per_row = [10, capacity].min
    
    rows.map do |row|
      (1..seats_per_row).map { |col| "#{row}#{col}" }
    end.flatten
  end
  
  def available_seats(showtime)
    booked_seats = showtime.bookings.where(status: 'confirmed').flat_map { |booking| booking.seats }
    seat_layout - booked_seats
  end
end
