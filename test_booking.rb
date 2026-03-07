#!/usr/bin/env ruby

require_relative 'config/environment'

puts "Creating test booking..."

# Get required data
user = User.first
showtime = Showtime.find(39159)
movie = showtime.movie
theater = showtime.theater

puts "User: #{user.email}"
puts "Movie: #{movie.title}"
puts "Showtime: #{showtime.start_time}"

# Create a booking
booking = Booking.create!(
  user: user,
  showtime: showtime,
  seats: ['A1', 'A2'],
  total_price: 500,
  status: 'pending'
)

puts "✅ Booking created: #{booking.id}"

# Send email
begin
  BookingMailer.booking_confirmation(booking).deliver_now
  puts "✅ Email sent successfully!"
  
  # Set session flag (simulate)
  puts "📧 Email should open automatically when you visit:"
  puts "   http://localhost:3001/bookings/#{booking.id}/payment"
  
rescue => e
  puts "❌ Email error: #{e.message}"
end
