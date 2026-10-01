module EntriesHelper
  STATUS_LABELS = {
    "to_watch" => "À voir",
    "watching" => "En cours",
    "watched" => "Vu"
  }.freeze

  def status_label(status)
    STATUS_LABELS.fetch(status.to_s)
  end

  def status_options
    Entry.statuses.keys.map { |status| [ status_label(status), status ] }
  end
end
