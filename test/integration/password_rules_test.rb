require "test_helper"

class PasswordRulesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_up(password)
    post user_registration_path, params: { user: { email: "nouveau@example.com", password: password,
                                                    password_confirmation: password } }
  end

  test "the sign-up form lists the rules" do
    get new_user_registration_path

    assert_select "#password-rules li", 5
    assert_select "input[type=password][aria-describedby='password-rules']"
  end

  test "the rules are listed in English" do
    patch change_locale_path, params: { locale: "en" }
    get new_user_registration_path

    assert_select "#password-rules", text: /an uppercase letter/
    assert_select "#password-rules", text: /at least 8 characters/
  end

  test "a weak password does not create an account and names the missing rules" do
    assert_no_difference "User.count" do
      sign_up("abcdefgh")
    end

    assert_response :unprocessable_entity
    assert_select ".nerv-errors", text: /majuscule/
    assert_select ".nerv-errors", text: /chiffre/
    assert_select ".nerv-errors", text: /caractère spécial/
  end

  test "the error messages are in English" do
    patch change_locale_path, params: { locale: "en" }

    sign_up("abcdefgh")

    assert_select ".nerv-errors", text: /uppercase letter/
  end

  test "a strong password creates the account" do
    assert_difference "User.count", 1 do
      sign_up("Passw0rd!2026")
    end
  end

  test "changing the password also requires the rules" do
    sign_in users(:one)

    put user_registration_path, params: { user: { password: "abcdefgh", password_confirmation: "abcdefgh",
                                                   current_password: "Passw0rd!2026" } }

    assert_response :unprocessable_entity
  end

  test "the account page lists the rules too" do
    sign_in users(:one)
    get edit_user_registration_path

    assert_select "#password-rules li", 5
  end

  test "the demo account is still created by the seed" do
    User.where(email: User::GUEST_EMAIL).destroy_all

    assert_nothing_raised { load Rails.root.join("db/seeds.rb") }
    assert User.exists?(email: User::GUEST_EMAIL)
  end
end
