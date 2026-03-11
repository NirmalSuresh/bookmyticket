class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_showtime, only: [:new, :create]
  before_action :set_booking, only: [:show, :payment, :payment_success, :payment_failed, :cancel]

  def index
    @bookings = current_user.bookings.includes(showtime: [:movie, :theater]).order(created_at: :desc)
  end

  def new
    @booking = Booking.new
    @movie = @showtime.movie
    @theater = @showtime.theater
    @screen = @showtime.screen
    @available_seats = @screen.available_seats(@showtime)
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.user = current_user
    @booking.showtime = @showtime
    @booking.status = 'pending'

    @booking.seats = parsed_seats
    @booking.total_price = booking_total_price(@booking.seats.count)

    if @booking.save
      @booking.update(razorpay_order_id: "order_demo_#{@booking.id}")
      redirect_to payment_movie_booking_path(@showtime.movie, @booking)
    else
      @movie = @showtime.movie
      @theater = @showtime.theater
      @screen = @showtime.screen
      @available_seats = @screen.available_seats(@showtime)
      flash.now[:alert] = @booking.errors.full_messages.join(', ')
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @movie = @booking.showtime.movie
    @theater = @booking.showtime.theater
    @showtime = @booking.showtime
  end

  def payment
    @movie = @booking.showtime.movie
    @theater = @booking.showtime.theater
    @showtime = @booking.showtime
  end

  def payment_success
    unless @booking.update(
      status: 'confirmed',
      razorpay_payment_id: "pay_demo_#{@booking.id}",
      razorpay_signature: "signature_demo_#{@booking.id}",
      paid_at: Time.current
    )
      redirect_to payment_movie_booking_path(@booking.showtime.movie, @booking),
                  alert: @booking.errors.full_messages.to_sentence.presence || 'Unable to confirm payment.'
      return
    end

    send_confirmation_email(@booking)

    redirect_to booking_path(@booking), notice: '🎉 Payment successful! Your booking is confirmed.'
  end

  def demo_booking
    @movie = Movie.find(params[:movie_id])
    @showtime = Showtime.find(params[:showtime_id])

    @booking = Booking.create!(
      user: current_user,
      showtime: @showtime,
      seats: ['A1', 'A2'],
      total_price: 300,
      status: 'confirmed',
      razorpay_payment_id: "pay_demo_#{Time.current.to_i}",
      razorpay_signature: "signature_demo_#{Time.current.to_i}",
      paid_at: Time.current
    )

    send_confirmation_email(@booking)

    redirect_to @booking, notice: 'Demo booking successful! Check your email for confirmation.'
  end

  def payment_failed
    redirect_to root_path, alert: 'Payment failed'
  end

  def cancel
    if @booking.user != current_user
      redirect_to bookings_path, alert: 'Not authorized.'
      return
    end
    if @booking.confirmed?
      redirect_to booking_path(@booking), alert: 'Confirmed bookings cannot be cancelled.'
      return
    end
    @booking.update!(status: 'cancelled')
    redirect_to bookings_path, notice: "Booking ##{@booking.id} has been cancelled."
  end

  private

  def set_showtime
    showtime_id = params[:showtime_id].presence || params.dig(:booking, :showtime_id).presence
    @showtime = Showtime.find(showtime_id)
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:showtime_id, :total_price)
  end

  def parsed_seats
    seats_param = params.dig(:booking, :seats)

    return [] if seats_param.blank?

    if seats_param.is_a?(String)
      JSON.parse(seats_param)
    else
      seats_param
    end
  rescue JSON::ParserError
    seats_param.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def booking_total_price(seat_count)
    base_amount = @showtime.price * seat_count
    convenience_fee = (base_amount * 0.02).round(2)
    base_amount + convenience_fee
  end

  def send_confirmation_email(booking)
    BookingMailer.booking_confirmation(booking).deliver_now
    session[:email_sent] = true
    session[:booking_id] = booking.id
  rescue StandardError => e
    Rails.logger.error("Failed to send booking confirmation email for booking #{booking.id}: #{e.message}")
  end
end
