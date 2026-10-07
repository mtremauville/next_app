class TmdbSearchesController < ApplicationController
  skip_after_action :verify_policy_scoped

  def index
    results = Tmdb::Search.new.call(params[:q])
    render json: results.map(&:to_h)
  rescue Tmdb::Error
    render json: { error: "Recherche indisponible" }, status: :bad_gateway
  end
end
