require "test_helper"

class TmdbSearchesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "returns an empty list for a short query" do
    sign_in users(:one)
    get tmdb_search_path(q: "a"), as: :json
    assert_response :success
    assert_equal [], response.parsed_body
  end

  test "redirects to sign in when signed out" do
    get tmdb_search_path(q: "inception")
    assert_redirected_to new_user_session_path
  end
end
