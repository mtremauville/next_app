module Recommendations
  class MoodPicks
    LIMIT = 6
    MAX_PAGE = 5

    Result = Struct.new(:mood, :in_list, :discover, :unavailable, keyword_init: true)

    def initialize(user, catalog: Tmdb::Catalog.new, random: Random.new)
      @user = user
      @catalog = catalog
      @random = random
    end

    def call(mood, type = "all")
      raise ArgumentError, "unknown mood" unless Moods::KEYS.include?(mood)
      raise ArgumentError, "unknown type" unless [ "all", *Moods::TYPES ].include?(type)

      types = type == "all" ? Moods::TYPES : [ type ]

      discover = begin
        discover_for(mood, types)
      rescue Tmdb::Error
        nil
      end

      Result.new(mood: mood, in_list: in_list_for(mood, types), discover: discover || [], unavailable: discover.nil?)
    end

    private

    def in_list_for(mood, types)
      entries = @user.entries.where(media_type: types).includes(:playlist)
      entries.select { |entry| Moods.match?(mood, entry) }.shuffle.first(LIMIT)
    end

    def discover_for(mood, types)
      owned = @user.entries.where.not(tmdb_id: nil).pluck(:media_type, :tmdb_id).to_set

      lists = types.map do |type|
        fetch(mood, type).reject { |item| owned.include?([ item.media_type, item.tmdb_id ]) }
      end

      interleave(lists).first(LIMIT)
    end

    def fetch(mood, type)
      filters = Moods.filters(mood, type)
      page = @random.rand(1..MAX_PAGE)

      items = @catalog.discover(type, filters, page: page).items
      items = @catalog.discover(type, filters, page: 1).items if items.empty? && page > 1
      items.shuffle
    end

    def interleave(lists)
      longest = lists.map(&:size).max.to_i
      (0...longest).flat_map { |index| lists.filter_map { |list| list[index] } }
    end
  end
end
