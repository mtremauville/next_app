module Recommendations
  module Moods
    KEYS = %w[nostalgic feel_good fight calm].freeze
    TYPES = %w[movie tv].freeze
    OLD_YEARS = 20

    SPECS = {
      "nostalgic" => {
        "movie" => { older_than_years: OLD_YEARS, rating: 7.0, votes: 500 },
        "tv" => { older_than_years: OLD_YEARS, rating: 7.0, votes: 200 }
      },
      "feel_good" => {
        "movie" => { with: [ 35, 10749, 10402, 10751 ], without: [ 27, 53, 80, 10752 ] },
        "tv" => { with: [ 35, 10751 ], without: [ 80, 10768 ] }
      },
      "fight" => {
        "movie" => { with: [ 28, 53, 80, 10752 ] },
        "tv" => { with: [ 10759, 80, 10768 ] }
      },
      "calm" => {
        "movie" => { with: [ 16, 99, 10751 ], without: [ 27, 53, 80, 10752, 28 ], max_runtime: 100 },
        "tv" => { with: [ 16, 99, 10751, 10762 ], without: [ 80, 10768, 10759 ], max_runtime: 30 }
      }
    }.freeze

    def self.filters(mood, media_type, today: Date.current)
      spec = SPECS.fetch(mood).fetch(media_type)

      params = {
        sort_by: "popularity.desc",
        "vote_count.gte": spec.fetch(:votes, 200),
        "vote_average.gte": spec.fetch(:rating, 6.5)
      }
      params[:with_genres] = spec[:with].join("|") if spec[:with]
      params[:without_genres] = spec[:without].join("|") if spec[:without]
      params[:"with_runtime.lte"] = spec[:max_runtime] if spec[:max_runtime]

      if spec[:older_than_years]
        date = (today - spec[:older_than_years].years).iso8601
        params[media_type == "movie" ? :"primary_release_date.lte" : :"first_air_date.lte"] = date
      end

      params
    end

    def self.match?(mood, entry, today: Date.current)
      return nostalgic_match?(entry, today) if mood == "nostalgic"
      return false unless entry.to_watch?

      spec = SPECS.dig(mood, entry.media_type)
      ids = entry.genre_id_list
      return false if spec.nil? || ids.empty?
      return false if spec[:without] && (ids & spec[:without]).any?
      return false if spec[:with] && (ids & spec[:with]).empty?

      !too_long?(spec, entry)
    end

    def self.too_long?(spec, entry)
      spec[:max_runtime] && entry.media_type == "movie" && entry.runtime_minutes &&
        entry.runtime_minutes > spec[:max_runtime]
    end

    def self.nostalgic_match?(entry, today)
      return true if entry.watched? && entry.rating.to_i >= 4

      year = entry.year.to_i
      entry.to_watch? && year.positive? && year <= today.year - OLD_YEARS
    end

    private_class_method :too_long?, :nostalgic_match?
  end
end
