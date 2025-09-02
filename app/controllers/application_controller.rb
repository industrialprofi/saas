class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "messages",
          partial: "shared/upgrade_note"
        )
      end
      format.html { redirect_to pricing_path, alert: "Доступ доступен только по платной подписке." }
      format.json { head :forbidden }
    end
  end
end
