require "test_helper"

class GuestSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.find_or_create_by!(email: User::GUEST_EMAIL) do |user|
      user.password = "password123"
    end
  end

  test "guest login signs in the guest user and redirects to root" do
    post guest_login_url
    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end
end
