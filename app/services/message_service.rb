class MessageService
  def initialize(message_id)
    @message      = Message.find message_id
    @bot_instance = message.bot_instance
  end

  def send_now
    return false if bot_instance.state != 'enabled'
    return false if service.channel.blank?

    message.log_response(response)
    message.update(sent_at: Time.current)
    message.ping_pusher_for_notification if message.notification
  end

  private

    attr_reader :message, :bot_instance

    def service
      @_service ||= PostMessageToSlackService.new(message, bot_instance.token)
    end

    def response
      @_response ||= service.call
    end
end
