require "test_helper"

class Recommendations::MoodsTest < ActiveSupport::TestCase
  Moods = Recommendations::Moods

  def entry(attrs = {})
    Entry.new({ media_type: "movie", status: :to_watch, genre_ids: "35" }.merge(attrs))
  end

  test "feel good movies combine genres with OR and exclude the dark ones" do
    filters = Moods.filters("feel_good", "movie")

    assert_equal "35|10749|10402|10751", filters[:with_genres]
    assert_equal "27|53|80|10752", filters[:without_genres]
    assert_equal "popularity.desc", filters[:sort_by]
    assert_equal 200, filters[:"vote_count.gte"]
    assert_equal 6.5, filters[:"vote_average.gte"]
  end

  test "nostalgic titles are old and well rated, with no genre filter" do
    today = Date.new(2026, 10, 20)

    movie = Moods.filters("nostalgic", "movie", today: today)
    assert_equal "2006-10-20", movie[:"primary_release_date.lte"]
    assert_equal 7.0, movie[:"vote_average.gte"]
    assert_nil movie[:with_genres]

    tv = Moods.filters("nostalgic", "tv", today: today)
    assert_equal "2006-10-20", tv[:"first_air_date.lte"]
    assert_nil tv[:"primary_release_date.lte"]
  end

  test "calm limits the runtime differently for movies and shows" do
    assert_equal 100, Moods.filters("calm", "movie")[:"with_runtime.lte"]
    assert_equal 30, Moods.filters("calm", "tv")[:"with_runtime.lte"]
  end

  test "an unknown mood or type has no filters" do
    assert_raises(KeyError) { Moods.filters("sad", "movie") }
    assert_raises(KeyError) { Moods.filters("calm", "person") }
  end

  test "a to-watch comedy fits feel good" do
    assert Moods.match?("feel_good", entry(genre_ids: "35,18"))
  end

  test "a dark genre rules a title out" do
    assert_not Moods.match?("feel_good", entry(genre_ids: "35,27"))
  end

  test "a watched title or one without genres never fits a genre mood" do
    assert_not Moods.match?("feel_good", entry(status: :watched))
    assert_not Moods.match?("feel_good", entry(genre_ids: nil))
  end

  test "genre ids are checked per media type" do
    assert Moods.match?("fight", entry(genre_ids: "53"))
    assert_not Moods.match?("fight", entry(media_type: "tv", genre_ids: "53"))
    assert Moods.match?("fight", entry(media_type: "tv", genre_ids: "10759"))
  end

  test "calm movies must be short, unknown runtimes are accepted, shows ignore the runtime" do
    assert_not Moods.match?("calm", entry(genre_ids: "16", runtime_minutes: 120))
    assert Moods.match?("calm", entry(genre_ids: "16", runtime_minutes: 90))
    assert Moods.match?("calm", entry(genre_ids: "16", runtime_minutes: nil))
    assert Moods.match?("calm", entry(media_type: "tv", genre_ids: "16", runtime_minutes: 900))
  end

  test "nostalgia fits well rated watched titles and old titles to watch" do
    today = Date.new(2026, 10, 20)

    assert Moods.match?("nostalgic", entry(status: :watched, rating: 5), today: today)
    assert_not Moods.match?("nostalgic", entry(status: :watched, rating: 3), today: today)
    assert Moods.match?("nostalgic", entry(year: "1999"), today: today)
    assert_not Moods.match?("nostalgic", entry(year: "2024"), today: today)
    assert_not Moods.match?("nostalgic", entry(year: nil), today: today)
  end
end
