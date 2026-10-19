class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :entries, dependent: :destroy
  has_many :playlists, dependent: :destroy
  validates :locale, inclusion: { in: ->(_user) { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  GUEST_EMAIL = "guest@next.tremic.fr".freeze
  def guest? = email == GUEST_EMAIL
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  def self.guest
    find_by!(email: GUEST_EMAIL)
  end

  def preferred_locale
    locale.presence&.to_sym
  end
end
