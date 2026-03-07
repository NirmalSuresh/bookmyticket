require "test_helper"

class BookingStepsControllerTest < ActionDispatch::IntegrationTest
  test "should get city" do
    get booking_steps_city_url
    assert_response :success
  end

  test "should get theater" do
    get booking_steps_theater_url
    assert_response :success
  end

  test "should get date" do
    get booking_steps_date_url
    assert_response :success
  end

  test "should get time" do
    get booking_steps_time_url
    assert_response :success
  end
end
