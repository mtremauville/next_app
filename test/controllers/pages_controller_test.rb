require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get home when signed in" do
    sign_in users(:one)
    get root_url
    assert_response :success
  end

  test "should redirect to sign in when signed out" do
    get root_url
    assert_redirected_to new_user_session_url
  end
end
