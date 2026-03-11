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
    # Pull all cities from DB, normalize duplicates (e.g. Bangalore/Bengaluru → Bengaluru)
    raw_cities = Theater.distinct.pluck(:city).compact.reject(&:empty?).sort
    # Normalize: prefer "Bengaluru" over "Bangalore", "Delhi" over "Delhi-NCR"
    city_aliases = { "Bangalore" => "Bengaluru", "Delhi-NCR" => "Delhi" }
    @available_cities = raw_cities
      .map { |c| city_aliases[c] || c }
      .uniq
      .sort
    # Fallback if DB is empty
    @available_cities = %w[Mumbai Delhi Bengaluru Hyderabad Chennai Kolkata Pune Ahmedabad] if @available_cities.empty?
    @current_city = session[:current_city] || 'Mumbai'
  end

  def current_city
    @current_city
  end
end
