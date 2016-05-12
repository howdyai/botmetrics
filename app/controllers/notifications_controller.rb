class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @notifications = @bot.notifications.page(params[:page])
    redirect_to new_bot_notification_path(@bot) if @notifications.blank?
  end

  def new
    @notification = @bot.notifications.build(bot_user_ids: BotUser.interacted_with(@bot))
  end

  def create
    @notification = @bot.notifications.build(model_params)

    if @notification.save
      SendNotificationJob.perform_async(@notification.id)

      redirect_to [@bot, @notification]
    else
      render :new
    end
  end

  def show
    @notification = Notification.find(params[:id])
  end

  private

    def model_params
      params.require(:notification).permit(:content, bot_user_ids: [])
    end
end
