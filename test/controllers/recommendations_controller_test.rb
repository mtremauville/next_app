require "test_helper"
require "minitest/mock"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  class FakeCatalog
    attr_reader :calls

    def initialize(error: nil, **items)
      @items = items
      @error = error
      @calls = []
    end

    def discover(media_type, filters = {}, page: 1)
      @calls << media_type
      raise Tmdb::Error, "down" if @error

      Tmdb::Catalog::Page.new(items: @items.fetch(media_type, []), page: page, total_pages: 5)
    end
  end

  setup { sign_in users(:one) }

  def item(id, type = "movie")
    Tmdb::Catalog::Item.new(tmdb_id: id, title: "Idée #{id}", media_type: type, year: "2001",
                            poster_path: "/p.jpg", overview: "")
  end

  def visit(path, catalog = FakeCatalog.new("movie" => [ item(1) ], "tv" => [ item(2, "tv") ]))
    Tmdb::Catalog.stub :new, ->(*) { catalog } do
      get path
    end
    catalog
  end

  test "the page requires a signed in user" do
    sign_out :user
    get recommendations_path

    assert_redirected_to new_user_session_path
  end

  test "without a mood the page shows the four moods and no results" do
    catalog = visit recommendations_path

    assert_response :success
    assert_select "h1", "Que regarder ?"
    assert_select "a.nerv-mood", 4
    assert_select "a.nerv-mood.is-active", count: 0
    assert_select ".nerv-section", count: 0
    assert_empty catalog.calls
  end

  test "a mood shows the titles of the list and the discoveries" do
    users(:one).entries.create!(title: "Ma comédie", media_type: "movie", tmdb_id: 7, genre_ids: "35", status: :to_watch)

    visit recommendations_path(mood: "feel_good", type: "movie")

    assert_select "a.nerv-mood.is-active", text: /Feel good/
    assert_select "h2", "Dans ta liste"
    assert_select ".nerv-gallery-title", text: "Ma comédie"
    assert_select "h2", "À découvrir"
    assert_select ".nerv-gallery-title", text: "Idée 1"
    assert_select ".nerv-add-button[data-tmdb-id='1'][data-media-type='movie']"
  end

  test "the quick add modal lists only my playlists" do
    visit recommendations_path(mood: "fight")

    assert_select "dialog[data-add-to-playlist-target='dialog']", count: 1
    assert_select "select#playlist_id option", text: "Films du dimanche"
    assert_select "select#playlist_id option", text: "Liste de l'autre", count: 0
  end

  test "the type tab selects the media type" do
    catalog = visit recommendations_path(mood: "calm", type: "tv")

    assert_select "nav.nerv-tabs a.is-active", text: "[ Séries ]"
    assert_equal [ "tv" ], catalog.calls.uniq
    assert_select "a.nerv-mood[href*='type=tv']", 4
  end

  test "an unknown mood or type is ignored" do
    catalog = visit recommendations_path(mood: "sad")
    assert_select ".nerv-section", count: 0
    assert_empty catalog.calls

    visit recommendations_path(mood: "calm", type: "person")
    assert_select "nav.nerv-tabs a.is-active", text: "[ Tous ]"
  end

  test "a list with nothing fitting says so" do
    visit recommendations_path(mood: "feel_good", type: "movie")

    assert_select "p", text: "Rien dans ta liste ne correspond à cette humeur pour l'instant."
  end

  test "an unavailable TMDB shows a message and keeps the page" do
    visit recommendations_path(mood: "feel_good"), FakeCatalog.new(error: true)

    assert_response :success
    assert_select ".nerv-flash--alert", text: /indisponibles/
  end

  test "the page is in English" do
    patch change_locale_path, params: { locale: "en" }
    visit recommendations_path(mood: "fight")

    assert_select "h1", "What to watch?"
    assert_select "a.nerv-mood.is-active", text: /Fired up/
    assert_select "h2", "In your list"
    assert_select "h2", "To discover"
  end

  test "the menu links to the page and highlights it" do
    visit recommendations_path

    assert_select "nav#side-menu a[href=?]", recommendations_path
    assert_select "nav#side-menu a.is-active", text: "[ Que regarder ? ]"
  end
end
