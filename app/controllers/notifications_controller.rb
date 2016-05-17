class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :find_notification,   only: [:show, :edit, :update, :destroy]
  before_action :valid_notification?, only: [:edit, :update, :destroy]

  layout 'app'

  def index
    @notifications = @bot.notifications.order(id: :desc).page(params[:page])
    redirect_to(new_bot_notification_path(@bot)) && return if @notifications.blank?

    TrackMixpanelEventJob.perform_async('Viewed Notifications Index Page', current_user.id)
  end

  def new
    @notification = @bot.notifications.build(bot_user_ids: BotUser.interacted_with(@bot))
    TrackMixpanelEventJob.perform_async('Viewed New Notification Page', current_user.id)
  end

  def create
    @notification = @bot.notifications.build(model_params)

    if @notification.save(context: :schedule)
      TrackMixpanelEventJob.perform_async('Created Notification', current_user.id, bot_users: @notification.bot_user_ids.count)

      send_or_queue_and_redirect
    else
      render :new
    end
  end

  def show
    @notification = Notification.find(params[:id])
    TrackMixpanelEventJob.perform_async('Viewed Notifications Show Page', current_user.id)
  end

  def edit
  end

  def update
    @notification.assign_attributes(model_params)

    if @notification.save(context: :schedule)
      send_or_queue_and_redirect
    else
      render :edit
    end
  end

  def destroy
    @notification.destroy

    redirect_to bot_notifications_path(@bot), notice: 'The notification has been deleted.'
  end

  private

    def find_notification
      @notification = @bot.notifications.find(params[:id])
    end

    def valid_notification?
      raise ActiveRecord::RecordNotFound if @notification.sent?
    end

    def model_params
      params.require(:notification).permit(:content, :scheduled_at, bot_user_ids: [])
    end

    def send_or_queue_and_redirect
      if @notification.send_immediately?
        SendNotificationJob.perform_async(@notification.id)

        redirect_to [@bot, @notification]
      else
        EnqueueNotificationJob.perform_async(@notification.id)

        redirect_to bot_notifications_path(@bot), notice: 'The notification has been queued to be sent at a later date.'
      end
    end
end
