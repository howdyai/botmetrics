class NotificationService
  def initialize(notification)
    @notification = notification
  end

  def send_now
    ActiveRecord::Base.transaction do
      delete_messages!
      create_messages!
    end

    send_messages
  end

  def enqueue_messages
    ActiveRecord::Base.transaction do
      delete_messages!
      create_messages!
    end
  end

  private

    attr_reader :notification

    def delete_messages!
      notification.messages.destroy_all
    end

    def create_messages!
      # binding.pry
      bot_users = FilterBotUsersService.new(notification.query_set).scope
      bot_users.each do |bot_user|
        message_object = Messages::Slack.new(message_params(bot_user))
        message_model  = message_object.save_for(bot_user.bot_instance, notification_params(bot_user))

        unless message_model
          Rails.logger.warn "[FAILED NOTIFICATION::MessageSave] Failed to send for Message #{message_model.inspect}"
        end
      end
    end

    def send_messages
      notification.reload.messages.each do |message|
        send_message(message)
      end
    end

    def send_message(message)
      SendMessageJob.perform_async(message.id)
    end

    def message_params(bot_user)
      {
        team_id: bot_user.bot_instance.team_id,
        user:    bot_user.uid,
        text:    notification.content
      }
    end

    def notification_params(bot_user)
      {
        notification: notification,
        scheduled_at: scheduled_at(bot_user)
      }.delete_if { |_, v| v.blank? }
    end

    def scheduled_at(bot_user)
      return nil if notification.scheduled_at.blank?

      if time_zone = bot_user.user_attributes['timezone']
        notification.scheduled_at.in_time_zone(time_zone)
      else
        Rails.logger.warn "[FAILED NOTIFICATION::TimeZone] Failed to schedule Notification #{notification.id} for BotUser #{bot_user.inspect}"
      end
    end
end
