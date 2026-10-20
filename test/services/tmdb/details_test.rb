require "test_helper"

class Tmdb::DetailsTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:payload) do
    def get(_path, _params = {}) = payload
  end

  class FailingClient
    def get(*) = raise(Tmdb::Error, "down")
  end

  test "movie runtime and genres" do
    client = FakeClient.new({ "runtime" => 148,
                              "genres" => [ { "id" => 878, "name" => "Science-Fiction" }, { "id" => 28, "name" => "Action" } ] })
    result = Tmdb::Details.new(client: client).call(27205, "movie")

    assert_equal 148, result.runtime_minutes
    assert_equal "Science-Fiction,Action", result.genres
  end

  test "returns the TMDB genre ids" do
    client = FakeClient.new({ "runtime" => 100,
                              "genres" => [ { "id" => 878, "name" => "Science-Fiction" }, { "id" => 28, "name" => "Action" } ] })
    result = Tmdb::Details.new(client: client).call(1, "movie")

    assert_equal [ 878, 28 ], result.genre_ids
  end

  test "tv runtime is episode length times episode count" do
    client = FakeClient.new({ "episode_run_time" => [ 50 ], "number_of_episodes" => 9, "genres" => [] })

    assert_equal 450, Tmdb::Details.new(client: client).call(95396, "tv").runtime_minutes
  end

  test "a title without genres gives empty values" do
    result = Tmdb::Details.new(client: FakeClient.new({ "runtime" => 90 })).call(1, "movie")

    assert_equal "", result.genres
    assert_equal [], result.genre_ids
  end

  test "returns nil when TMDB is unavailable" do
    assert_nil Tmdb::Details.new(client: FailingClient.new).call(1, "movie")
  end

  test "returns nil for an unknown media type" do
    assert_nil Tmdb::Details.new(client: FakeClient.new({})).call(1, "person")
  end

  test "returns nil without an id" do
    assert_nil Tmdb::Details.new(client: FakeClient.new({})).call(nil, "movie")
  end
end
