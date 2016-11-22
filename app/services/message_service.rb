class MessageService
  def initialize(message)
    @message = message
    @bot_instance = message.bot_instance
  end

  def send_now
    return false if bot_instance.state != 'enabled'
    return false if (message.provider == 'slack' && service.channel.blank?)

    message.log_response(response)
    message.update(sent_at: Time.current)
    ping_pusher_for_new_message_notification if notification
  end

  private

  attr_reader :message, :bot_instance

  delegate :notification, :success, :user, :channel, to: :message
  def service
    @_service ||= case message.provider
                  when 'slack'    then PostMessageToSlackService.new(message, bot_instance.token)
                  when 'facebook' then PostMessageToFacebookService.new(message, bot_instance.token)
                  when 'kik'      then PostMessageToKikService.new(message, bot_instance.token, bot_instance.uid)
                  end
  end

  def response
    @_response ||= service.call
  end

  def ping_pusher_for_new_message_notification
    PusherJob.perform_async(
      "notification",
      "notification-#{notification.id}",
      {
        ok: success,
        recipient: (user || channel),
        sent: notification.messages.sent.count
      }.to_json
    )
  end
end
