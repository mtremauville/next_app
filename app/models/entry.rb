class Entry < ApplicationRecord
  belongs_to :user
  belongs_to :playlist, optional: true

  enum :status, { to_watch: 0, watching: 1, watched: 2 }

  validates :title, presence: true
  validates :status, presence: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
  validate :playlist_belongs_to_same_user

  private

  def playlist_belongs_to_same_user
    return if playlist.nil? || playlist.user_id == user_id

    errors.add(:playlist, "must belong to the same user")
  end
end
