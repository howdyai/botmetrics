class NotificationService
  def initialize(notification)
    @notification = notification
  end

  def send_now
    bot_users = BotUser.where(id: notification.bot_user_ids)
    bot_users.find_each do |bot_user|
      message = Messages::Slack.new(model_params(bot_user, notification))

      if message_object = message.save_for(bot_user.bot_instance, notification: notification)
        SendMessageJob.perform_async(message_object.id)
      else
        Rails.logger.warn "[FAILED NOTIFICATION] Failed to send for Message #{message_object.inspect}"
      end
    end
  end

  private

    attr_accessor :notification

    def model_params(bot_user, notification)
      {
        team_id: bot_user.bot_instance.team_id,
        user:    bot_user.uid,
        text:    notification.content
      }
    end
end
