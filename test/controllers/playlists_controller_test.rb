require "test_helper"

class PlaylistsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:one) }

  test "index lists only my playlists" do
    get playlists_path
    assert_response :success
    assert_select "h2", text: "Films du dimanche"
    assert_select "h2", text: "Liste de l'autre", count: 0
  end

  test "create adds a playlist for the current user" do
    assert_difference -> { users(:one).playlists.count }, 1 do
      post playlists_path, params: { playlist: { name: "Séries" } }
    end
    assert_redirected_to playlists_path
  end

  test "create with a blank name re-renders the form" do
    assert_no_difference "Playlist.count" do
      post playlists_path, params: { playlist: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "update renames my playlist" do
    patch playlist_path(playlists(:empty_list)), params: { playlist: { name: "Renommée" } }
    assert_redirected_to playlists_path
    assert_equal "Renommée", playlists(:empty_list).reload.name
  end

  test "destroy removes the playlist but keeps its entries" do
    assert_difference "Playlist.count", -1 do
      delete playlist_path(playlists(:sunday_movies))
    end
    assert_redirected_to playlists_path
    assert_nil entries(:inception).reload.playlist_id
  end

  test "cannot edit another user's playlist" do
    get edit_playlist_path(playlists(:other_user_list))
    assert_response :not_found
  end

  test "redirects to sign in when signed out" do
    sign_out :user
    get playlists_path
    assert_redirected_to new_user_session_path
  end
end
