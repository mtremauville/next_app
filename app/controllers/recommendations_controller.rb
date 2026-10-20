class RecommendationsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    @type = Recommendations::Moods::TYPES.include?(params[:type]) ? params[:type] : "all"
    @mood = Recommendations::Moods::KEYS.find { |key| key == params[:mood] }
    @playlists = current_user.playlists.order(:name)
    @picks = Recommendations::MoodPicks.new(current_user).call(@mood, @type) if @mood
  end
end
