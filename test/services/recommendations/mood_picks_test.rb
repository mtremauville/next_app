require "test_helper"

class Recommendations::MoodPicksTest < ActiveSupport::TestCase
    class FakeCatalog
      attr_reader :calls

      def initialize(error: nil, first_page_only: false, **items)
        @items = items
        @error = error
        @first_page_only = first_page_only
        @calls = []
      end

      def discover(media_type, filters = {}, page: 1)
        @calls << [ media_type, filters, page ]
        raise Tmdb::Error, "down" if @error

        items = @first_page_only && page > 1 ? [] : @items.fetch(media_type, [])
        Tmdb::Catalog::Page.new(items: items, page: page, total_pages: 5)
      end
    end

  class FixedRandom
    def rand(limit)
      limit.is_a?(Range) ? limit.max : 0
    end
  end

  def item(id, type = "movie")
    Tmdb::Catalog::Item.new(tmdb_id: id, title: "Titre #{id}", media_type: type, year: "2001",
                            poster_path: nil, overview: "")
  end

  def picks(catalog, user: users(:one), random: Random.new)
    Recommendations::MoodPicks.new(user, catalog: catalog, random: random)
  end

  def own(attrs = {})
    users(:one).entries.create!({ title: "Mon titre", media_type: "movie", status: :to_watch }.merge(attrs))
  end

  test "discoveries never include a title already in the list" do
    own(tmdb_id: 2)
    catalog = FakeCatalog.new("movie" => [ item(1), item(2), item(3) ])

    result = picks(catalog).call("feel_good", "movie")

    assert_equal [ 1, 3 ], result.discover.map(&:tmdb_id).sort
    assert_not result.unavailable
  end

  test "a watched title is not suggested again" do
    own(tmdb_id: 1, status: :watched)

    result = picks(FakeCatalog.new("movie" => [ item(1), item(2) ])).call("feel_good", "movie")

    assert_equal [ 2 ], result.discover.map(&:tmdb_id)
  end

  test "there are at most six discoveries" do
    catalog = FakeCatalog.new("movie" => (1..20).map { |id| item(id) })

    assert_equal 6, picks(catalog).call("fight", "movie").discover.size
  end

  test "all types mix movies and series" do
    catalog = FakeCatalog.new("movie" => (1..6).map { |id| item(id) },
                              "tv" => (11..16).map { |id| item(id, "tv") })

    result = picks(catalog).call("feel_good", "all")

    assert_equal 6, result.discover.size
    assert_equal({ "movie" => 3, "tv" => 3 }, result.discover.map(&:media_type).tally)
    assert_equal %w[movie tv], catalog.calls.map(&:first).uniq.sort
  end

  test "a single type only asks for that type" do
    catalog = FakeCatalog.new("tv" => [ item(1, "tv") ])

    picks(catalog).call("calm", "tv")

    assert_equal [ "tv" ], catalog.calls.map(&:first).uniq
  end

  test "the mood filters are sent to TMDB" do
    catalog = FakeCatalog.new("movie" => [ item(1) ])

    picks(catalog).call("feel_good", "movie")

    assert_equal "35|10749|10402|10751", catalog.calls.first[1][:with_genres]
  end

  test "it falls back to the first page when the picked page is empty" do
    catalog = FakeCatalog.new("movie" => [ item(1) ], first_page_only: true)

    result = picks(catalog, random: FixedRandom.new).call("fight", "movie")

    assert_equal [ 5, 1 ], catalog.calls.map(&:last)
    assert_equal [ 1 ], result.discover.map(&:tmdb_id)
  end

  test "an unavailable TMDB is reported and the list still comes back" do
    own(tmdb_id: 5, genre_ids: "35")

    result = picks(FakeCatalog.new(error: true)).call("feel_good", "movie")

    assert result.unavailable
    assert_empty result.discover
    assert_equal [ 5 ], result.in_list.map(&:tmdb_id)
  end

  test "the list only holds titles that fit the mood and the type" do
    own(title: "Comédie", tmdb_id: 1, genre_ids: "35")
    own(title: "Horreur", tmdb_id: 2, genre_ids: "35,27")
    own(title: "Série", tmdb_id: 3, media_type: "tv", genre_ids: "35")

    movies = picks(FakeCatalog.new).call("feel_good", "movie")
    all = picks(FakeCatalog.new).call("feel_good", "all")

    assert_equal [ "Comédie" ], movies.in_list.map(&:title)
    assert_equal [ "Comédie", "Série" ], all.in_list.map(&:title).sort
  end

  test "nostalgia offers the titles loved in the past" do
    own(title: "Adoré", tmdb_id: 1, status: :watched, rating: 5)
    own(title: "Moyen", tmdb_id: 2, status: :watched, rating: 2)

    result = picks(FakeCatalog.new).call("nostalgic", "movie")

    assert_equal [ "Adoré" ], result.in_list.map(&:title)
  end

  test "another user's titles are never read" do
    users(:two).entries.create!(title: "Secret", media_type: "movie", tmdb_id: 9, genre_ids: "35", status: :to_watch)

    result = picks(FakeCatalog.new).call("feel_good", "movie")

    assert_empty result.in_list
  end

  test "the list is limited to six titles" do
    8.times { |index| own(title: "Film #{index}", tmdb_id: 100 + index, genre_ids: "35") }

    assert_equal 6, picks(FakeCatalog.new).call("feel_good", "movie").in_list.size
  end

  test "an unknown mood or type is refused" do
    assert_raises(ArgumentError) { picks(FakeCatalog.new).call("sad") }
    assert_raises(ArgumentError) { picks(FakeCatalog.new).call("calm", "person") }
  end
end
