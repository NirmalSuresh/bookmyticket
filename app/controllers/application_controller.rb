class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_location_context

  helper_method :current_city
  
  layout 'application'
  
  def devise_layout
    if devise_controller?
      'devise/session'
    else
      'application'
  end

  def set_city
    city = params[:city].to_s.strip
    if @available_cities.include?(city)
      session[:current_city] = city
      session[:booking_city] = city
      redirect_back fallback_location: root_path, notice: "City changed to #{city}"
    else
      redirect_back fallback_location: root_path, alert: 'Invalid city selected'
    end
  end

  def test_email
    user = User.first
    booking = Booking.where(status: 'confirmed').first
    
    if user && booking
      begin
        BookingMailer.booking_confirmation(booking).deliver_now
        render plain: "✅ Test email sent successfully! Check http://localhost:3001/letter_opener to view it."
      rescue => e
        render plain: "❌ Error sending email: #{e.message}"
      end
    else
      render plain: "❌ No user or booking found"
    end
  end
  
  def test_auto_email
    # Set session flag and redirect to payment page to test auto opening
    session[:email_sent] = true
    session[:booking_id] = Booking.first&.id
    redirect_to "/bookings/#{Booking.first&.id}/payment", notice: "Test email auto-opening enabled!"
  end
  
  def show_test_email
    render file: Rails.root.join('public', 'email_test.html'), layout: false
  end
  
  def clear_email_session
    session[:email_sent] = false
    session[:booking_id] = nil
    render json: { success: true }
  end

  private

  def set_location_context
    @available_cities = Showtime.joins(:theater)
                                .where('showtimes.start_time > ?', Time.current)
                                .where.not(theaters: { city: [nil, ""] })
                                .distinct
                                .order('theaters.city')
                                .pluck('theaters.city')

    if @available_cities.empty?
      @available_cities = Theater.where.not(city: [nil, ""]).distinct.order(:city).pluck(:city)
    end

    chosen_city = session[:current_city]
    if chosen_city.blank? || !@available_cities.include?(chosen_city)
      chosen_city = @available_cities.first
      session[:current_city] = chosen_city
    end

    @current_city = chosen_city
  end

  def current_city
    @current_city
  end
end
