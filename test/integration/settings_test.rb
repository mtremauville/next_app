require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @guest = User.find_or_create_by!(email: User::GUEST_EMAIL) { |user| user.password = "password123" }
  end

  test "the settings page requires a signed in user" do
    get settings_path
    assert_redirected_to new_user_session_path
  end

  test "the settings page lists the language and the account actions" do
    sign_in users(:one)
    get settings_path

    assert_response :success
    assert_select "h1", "Réglages"
    assert_select "nav.nerv-locale--settings button[lang=fr][aria-pressed=true]"
    assert_select "nav.nerv-locale--settings button[lang=en][aria-pressed=false]"
    assert_select "section.nerv-danger-zone dialog form[action=?]", user_registration_path
  end

  test "changing the language saves it on the account and in the cookie" do
    sign_in users(:one)

    patch settings_path, params: { locale: "en" }

    assert_redirected_to settings_path
    assert_equal "en", users(:one).reload.locale
    assert_equal "en", cookies[:locale]
    assert_equal "Language saved.", flash[:notice]
  end

  test "the saved language wins over the browser language" do
    users(:one).update!(locale: "en")
    sign_in users(:one)

    get entries_path, headers: { "Accept-Language" => "fr-FR" }

    assert_select "html[lang=en]"
  end

  test "the saved language wins over the cookie" do
    users(:one).update!(locale: "en")
    sign_in users(:one)
    patch change_locale_path, params: { locale: "fr" }

    get entries_path

    assert_select "html[lang=en]"
  end

  test "an account without a saved language keeps the cookie" do
    sign_in users(:one)
    patch change_locale_path, params: { locale: "en" }

    get entries_path

    assert_select "html[lang=en]"
    assert_nil users(:one).reload.locale
  end

  test "an unknown language changes nothing" do
    sign_in users(:one)

    patch settings_path, params: { locale: "de" }

    assert_nil users(:one).reload.locale
    assert_equal "Langue inconnue.", flash[:alert]
  end

  test "the demo account never saves its language" do
    post guest_login_url

    patch settings_path, params: { locale: "en" }

    assert_nil @guest.reload.locale
    assert_equal "en", cookies[:locale]
  end

  test "the demo account can choose a language but cannot delete itself" do
    post guest_login_url
    get settings_path

    assert_response :success
    assert_select "nav.nerv-locale--settings"
    assert_select "section.nerv-danger-zone", count: 0
    assert_select "p.nerv-hint", text: /partagé/
  end

  test "the menu links to the settings and no longer to the account page" do
    sign_in users(:one)
    get entries_path

    assert_select "nav#side-menu a[href=?]", settings_path
    assert_select "nav#side-menu a[href=?]", edit_user_registration_path, count: 0
  end

  test "the settings link is highlighted on the settings and the account pages" do
    sign_in users(:one)

    get settings_path
    assert_select "nav#side-menu a.is-active", text: "[ Réglages ]"

    get edit_user_registration_path
    assert_select "nav#side-menu a.is-active", text: "[ Réglages ]"
  end

  test "deleting the account from the settings removes the user and their data" do
    sign_in users(:one)
    entries_count = users(:one).entries.count
    assert entries_count.positive?

    assert_difference "User.count", -1 do
      assert_difference "Entry.count", -entries_count do
        delete user_registration_path
      end
    end

    assert_redirected_to root_path
  end

  test "an invalid saved language is refused by the model" do
    user = users(:one)
    user.locale = "de"

    assert_not user.valid?
  end
end
