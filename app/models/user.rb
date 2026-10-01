class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :entries, dependent: :destroy
  GUEST_EMAIL = "guest@next.tremic.fr".freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.guest
    find_by!(email: GUEST_EMAIL)
  end
end
