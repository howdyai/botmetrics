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
    notification.messages.where(sent_at: nil).destroy_all
  end

  def create_messages!
    bot_users = FilterBotUsersService.new(notification.query_set).
                  scope.
                  where("bot_users.uid NOT IN (?)", notification.messages.select("messages.message_attributes ->> 'user'"))

    bot_users.find_each(batch_size: 500) do |bot_user|
      message_object = case bot_user.provider
                       when 'slack'    then Messages::Slack.new(message_params(bot_user))
                       when 'facebook' then Messages::Facebook.new(message_params(bot_user))
                       when 'kik'      then Messages::Kik.new(message_params(bot_user))
                       end
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
    case bot_user.provider
    when 'slack'
      {
        team_id: bot_user.bot_instance.team_id,
        user:    bot_user.uid,
        text:    notification.content
      }
    when 'facebook', 'kik'
      {
        user:    bot_user.uid,
        text:    notification.content
      }
    end
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
      if ActiveSupport::TimeZone[time_zone]
        notification.scheduled_at.in_time_zone(time_zone)
      elsif ActiveSupport::TimeZone[time_zone = time_zone.to_f.round]
        notification.scheduled_at.in_time_zone(time_zone)
      else
        notification.scheduled_at.in_time_zone('GMT')
      end
    else
      Rails.logger.warn "[FAILED NOTIFICATION::TimeZone] Failed to schedule Notification #{notification.id} for BotUser #{bot_user.inspect}"
      notification.scheduled_at.in_time_zone('GMT')
    end
  end
end
