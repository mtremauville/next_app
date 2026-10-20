require "test_helper"

class SignInRedirectTest < ActionDispatch::IntegrationTest
  PASSWORD = "Passw0rd!2026".freeze

  setup do
    @user = User.create!(email: "redirect@example.com", password: PASSWORD, password_confirmation: PASSWORD)
    User.find_or_create_by!(email: User::GUEST_EMAIL) { |user| user.password = "#{SecureRandom.hex(16)}Aa1!" }
  end

  def sign_in_with(email, password)
    post user_session_path, params: { user: { email: email, password: password } }
  end

  test "signing in leads to the mood recommendations" do
    sign_in_with(@user.email, PASSWORD)

    assert_redirected_to recommendations_path
  end

  test "the page that required a sign-in is still reached afterwards" do
    get entries_path
    assert_redirected_to new_user_session_path

    sign_in_with(@user.email, PASSWORD)

    assert_redirected_to entries_path
  end

  test "signing up leads to the mood recommendations" do
    post user_registration_path, params: { user: { email: "nouveau@example.com", password: PASSWORD,
                                                    password_confirmation: PASSWORD } }

    assert_redirected_to recommendations_path
  end

  test "the demo account leads to the mood recommendations" do
    post guest_login_url

    assert_redirected_to recommendations_path
  end

  test "a wrong password stays on the sign-in page" do
    sign_in_with(@user.email, "mauvais")

    assert_response :unprocessable_entity
    assert_select "h2", "Connexion"
  end

  test "the logo still leads to the home page" do
    sign_in_with(@user.email, PASSWORD)
    get recommendations_path

    assert_select "header a.nerv-logo[href=?]", root_path
  end
end
