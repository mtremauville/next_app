class GuestSessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :create

  def create
    sign_in(User.guest)
    redirect_to root_path, notice: "Bienvenue dans la démo !"
  end
end
