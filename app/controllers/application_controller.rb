class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  force_ssl if: -> { Rails.env.production? && !(params[:controller] == 'static' && params[:action] == 'letsencrypt') }

  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  include Mixpanelable

  protected

    def record_not_found
      head :not_found
    end

    def find_bot
      @bot = current_user.bots.find_by!(uid: params[:bot_id] || params[:id])
    end
end
