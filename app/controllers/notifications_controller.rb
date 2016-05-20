class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @notifications = @bot.notifications.page(params[:page])

    if @notifications.blank?
      redirect_to(new_bot_notification_path(@bot)) && return
    end
    TrackMixpanelEventJob.perform_async('Viewed Notifications Index Page', current_user.id)
  end

  def new
    @notification = @bot.notifications.build(bot_user_ids: BotUser.interacted_with(@bot))
    TrackMixpanelEventJob.perform_async('Viewed New Notification Page', current_user.id)
  end

  def create
    @notification = @bot.notifications.build(model_params)

    if @notification.save
      TrackMixpanelEventJob.perform_async('Created Notification', current_user.id, bot_users: @notification.bot_user_ids.count)
      SendNotificationJob.perform_async(@notification.id)

      redirect_to [@bot, @notification]
    else
      render :new
    end
  end

  def show
    @notification = Notification.find(params[:id])
    TrackMixpanelEventJob.perform_async('Viewed Notifications Show Page', current_user.id)
  end

  private

    def model_params
      params.require(:notification).permit(:content, bot_user_ids: [])
    end
end
