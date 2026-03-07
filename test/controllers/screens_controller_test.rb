require "test_helper"

class ScreensControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get screens_show_url
    assert_response :success
  end
end
