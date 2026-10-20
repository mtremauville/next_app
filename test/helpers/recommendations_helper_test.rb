require "test_helper"

class RecommendationsHelperTest < ActionView::TestCase
  test "every mood has a Font Awesome icon" do
    Recommendations::Moods::KEYS.each do |mood|
      assert_match(/class="fa-solid fa-[a-z-]+"/, mood_icon(mood))
    end
  end

  test "the icons list matches the moods" do
    assert_equal Recommendations::Moods::KEYS.sort, RecommendationsHelper::ICONS.keys.sort
  end

  test "icons are decorative" do
    assert_includes mood_icon("calm"), 'aria-hidden="true"'
  end

  test "an unknown mood has no icon" do
    assert_raises(KeyError) { mood_icon("sad") }
  end
end
