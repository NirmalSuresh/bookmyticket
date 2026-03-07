require "test_helper"

class Admin::TheatersControllerTest < ActionDispatch::IntegrationTest
  test "should get Theaters" do
    get admin_theaters_Theaters_url
    assert_response :success
  end

  test "should get Screens" do
    get admin_theaters_Screens_url
    assert_response :success
  end

  test "should get Showtimes" do
    get admin_theaters_Showtimes_url
    assert_response :success
  end
end
