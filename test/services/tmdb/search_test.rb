require "test_helper"

class Tmdb::SearchTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(payload)
      @payload = payload
    end

    def get(_path, _params = {})
      @payload
    end
  end

  test "maps movies and tv shows and ignores people" do
    payload = {
      "results" => [
        { "id" => 1, "media_type" => "movie", "title" => "Inception",
          "release_date" => "2010-07-15", "poster_path" => "/abc.jpg", "overview" => "Rêves" },
        { "id" => 2, "media_type" => "tv", "name" => "Severance",
          "first_air_date" => "2022-02-17", "poster_path" => nil, "overview" => "Bureau" },
        { "id" => 3, "media_type" => "person", "name" => "Acteur" }
      ]
    }

    results = Tmdb::Search.new(client: FakeClient.new(payload)).call("incep")

    assert_equal 2, results.size
    assert_equal "Inception", results.first.title
    assert_equal "2010", results.first.year
    assert_equal "https://image.tmdb.org/t/p/w185/abc.jpg", results.first.poster_url
    assert_equal "Severance", results.last.title
    assert_nil results.last.poster_url
    assert_equal "/abc.jpg", results.first.poster_path
  end

  test "returns an empty list for a query shorter than 2 characters" do
    assert_equal [], Tmdb::Search.new(client: FakeClient.new({})).call("a")
  end

  test "returns an empty list when there are no results" do
    assert_equal [], Tmdb::Search.new(client: FakeClient.new({ "results" => [] })).call("zzzz")
  end
end
