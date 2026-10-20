module RecommendationsHelper
  EMOJI = { "nostalgic" => "🕰️", "feel_good" => "😊", "fight" => "😈", "calm" => "🌿" }.freeze

  def mood_emoji(mood) = EMOJI.fetch(mood)
end
