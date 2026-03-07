#!/usr/bin/env ruby

require_relative 'config/environment'

puts "Testing email system..."

# Get a user and booking
user = User.first
booking = Booking.where(status: 'confirmed').first

puts "User: #{user.email}"
puts "Booking: #{booking.id} - #{booking.showtime.movie.title}"

# Test sending email
puts "Attempting to send test email..."
begin
  BookingMailer.booking_confirmation(booking).deliver_now
  puts "✅ Email sent successfully!"
  
  # Check if letter_opener created the email file
  if Dir.exist?('/tmp/letter_opener')
    emails = Dir.glob('/tmp/letter_opener/*.html')
    puts "📧 Found #{emails.count} email(s) in /tmp/letter_opener/"
    emails.each { |email| puts "   - #{email}" }
  else
    puts "❌ /tmp/letter_opener directory not found"
  end
  
rescue => e
  puts "❌ Error sending email: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end
