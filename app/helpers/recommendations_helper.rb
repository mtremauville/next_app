module RecommendationsHelper
  ICONS = {
    "nostalgic" => "fa-clock-rotate-left",
    "feel_good" => "fa-face-smile",
    "fight" => "fa-fire",
    "calm" => "fa-leaf"
  }.freeze

  def mood_icon(mood)
    tag.i(class: "fa-solid #{ICONS.fetch(mood)}", aria: { hidden: true })
  end
end
