class BookingMailer < ApplicationMailer
  def booking_confirmation(booking)
    @booking = booking
    @movie = booking.showtime.movie
    @theater = booking.showtime.theater
    @showtime = booking.showtime
    
    mail(
      to: booking.user.email,
      subject: "Booking Confirmation - #{@movie.title} - #{@showtime.start_time.strftime('%d %b %Y, %I:%M %p')}"
    )
  end
  
  def booking_cancellation(booking)
    @booking = booking
    @movie = booking.showtime.movie
    @theater = booking.showtime.theater
    @showtime = booking.showtime
    
    mail(
      to: booking.user.email,
      subject: "Booking Cancelled - #{@movie.title} - Refund Initiated"
    )
  end
end
