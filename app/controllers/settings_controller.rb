class SettingsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show; end

  def update
    locale = params[:locale].to_s

    unless I18n.available_locales.map(&:to_s).include?(locale)
      return redirect_to settings_path, alert: t("flash.settings.unknown_language"), status: :see_other
    end

    current_user.update!(locale: locale) unless current_user.guest?
    cookies[:locale] = { value: locale, expires: 1.year.from_now, same_site: :lax, secure: Rails.env.production? }

    redirect_to settings_path, notice: I18n.with_locale(locale) { t("flash.settings.language_saved") }, status: :see_other
  end
end
