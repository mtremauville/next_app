class Entry < ApplicationRecord
  belongs_to :user

  enum :status, { to_watch: 0, watching: 1, watched: 2 }

  validates :title, presence: true
  validates :status, presence: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
end
