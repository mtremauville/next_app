require "test_helper"

class NoEmojiTest < ActiveSupport::TestCase
  PATTERN = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/

  test "the interface uses icons, not emojis" do
    files = Dir[
      Rails.root.join("app/{views,helpers}/**/*.{erb,rb}").to_s,
      Rails.root.join("config/locales/*.yml").to_s
    ]

    offenders = files.flat_map do |file|
      File.readlines(file).each_with_index.filter_map do |line, index|
        "#{file.sub("#{Rails.root}/", '')}:#{index + 1}" if line.match?(PATTERN)
      end
    end

    assert_empty offenders, "Emoji à remplacer par une icône : #{offenders.join(', ')}"
  end
end
