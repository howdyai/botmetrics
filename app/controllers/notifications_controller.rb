class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :find_notification,   only: [:show, :destroy]
  before_action :valid_notification?, only: [:destroy]

  layout 'app'

  def index
    @notifications = @bot.notifications.order(id: :desc).page(params[:page])
    redirect_to(step_1_bot_new_notification_index_path(@bot)) && return if @notifications.blank?

    TrackMixpanelEventJob.perform_async('Viewed Notifications Index Page', current_user.id)
  end

  def show
    @send_count = FilterBotUsersService.new(@notification.query_set).scope.size

    TrackMixpanelEventJob.perform_async('Viewed Notifications Show Page', current_user.id)
  end

  def destroy
    @notification.destroy

    redirect_to bot_notifications_path(@bot), notice: 'The notification has been deleted.'
  end

  private

    def find_notification
      @notification = @bot.notifications.find_by!(uid: params[:id])
    end

    def valid_notification?
      raise ActiveRecord::RecordNotFound if @notification.sent?
    end

    def model_params
      params.require(:notification).permit(:content, :scheduled_at)
    end
end
