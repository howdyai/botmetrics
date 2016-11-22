class BotUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  def update
    @bot_user = BotUser.where(uid: params[:id], bot_instance_id: @bot.instances.select(:id)).first
    raise ActiveRecord::RecordNotFound if @bot_user.blank?

    if (tz = params[:user][:timezone]).present? && ActiveSupport::TimeZone[tz].present?
      @bot_user.user_attributes[:timezone] = tz
      @bot_user.save

      head :accepted
    else
      respond_to do |format|
        format.json { render json: { error: "no valid timezone provided" }, status: :bad_request }
      end
    end
  end
end
