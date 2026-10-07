module Tmdb
  class Search
    IMAGE_BASE = "https://image.tmdb.org/t/p/w185".freeze

    Result = Struct.new(:tmdb_id, :title, :media_type, :year, :poster_url, :overview, keyword_init: true)

    def initialize(client: Client.new)
      @client = client
    end

    def call(query)
      return [] if query.to_s.strip.length < 2

      data = @client.get("/search/multi", query: query.strip, language: "fr-FR", include_adult: false)

      data.fetch("results", [])
          .select { |item| %w[movie tv].include?(item["media_type"]) }
          .first(8)
          .map { |item| build_result(item) }
    end

    private

    def build_result(item)
      date = item["release_date"].presence || item["first_air_date"].presence

      Result.new(
        tmdb_id: item["id"],
        title: item["title"].presence || item["name"],
        media_type: item["media_type"],
        year: date&.slice(0, 4),
        poster_url: item["poster_path"] && "#{IMAGE_BASE}#{item['poster_path']}",
        overview: item["overview"]
      )
    end
  end
end
