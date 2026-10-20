class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :apply_account_locale

  after_action :verify_authorized, unless: :skip_authorization_check?
  after_action :verify_policy_scoped, if: :check_policy_scope?

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || recommendations_path
  end

  def skip_authorization_check?
    devise_controller? || action_name == "index"
  end

  def check_policy_scope?
    !devise_controller? && action_name == "index"
  end

  def forbidden
    redirect_back_or_to root_path, alert: t("flash.forbidden"), status: :see_other
  end
  def apply_account_locale
    return unless current_user&.preferred_locale
    return if current_user.guest?

    I18n.locale = current_user.preferred_locale
    cookies[:locale] = { value: current_user.preferred_locale.to_s, expires: 1.year.from_now,
                         same_site: :lax, secure: Rails.env.production? }
  end
end
