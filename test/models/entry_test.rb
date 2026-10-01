require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "is valid with a title, a status and a user" do
    assert Entry.new(title: "Dune", user: users(:one)).valid?
  end

  test "defaults to the to_watch status" do
    assert_equal "to_watch", Entry.new.status
  end

  test "requires a title" do
    entry = Entry.new(user: users(:one))
    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
  end

  test "rejects a rating outside 1..5" do
    entry = Entry.new(title: "Dune", user: users(:one), rating: 6)
    assert_not entry.valid?
  end

  test "allows a blank rating" do
    assert Entry.new(title: "Dune", user: users(:one), rating: nil).valid?
  end

  test "can belong to a playlist of the same user" do
    entry = Entry.new(title: "Dune", user: users(:one), playlist: playlists(:sunday_movies))
    assert entry.valid?
  end

  test "rejects a playlist owned by another user" do
    entry = Entry.new(title: "Dune", user: users(:one), playlist: playlists(:other_user_list))
    assert_not entry.valid?
  end
end
