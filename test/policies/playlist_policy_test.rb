require "test_helper"

class PlaylistPolicyTest < ActiveSupport::TestCase
  test "owner can edit, update and destroy" do
    policy = PlaylistPolicy.new(users(:one), playlists(:sunday_movies))
    assert policy.edit?
    assert policy.update?
    assert policy.destroy?
  end

  test "another user cannot" do
    policy = PlaylistPolicy.new(users(:two), playlists(:sunday_movies))
    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns only own playlists" do
    scope = PlaylistPolicy::Scope.new(users(:one), Playlist).resolve
    assert_includes scope, playlists(:sunday_movies)
    assert_not_includes scope, playlists(:other_user_list)
  end
end
