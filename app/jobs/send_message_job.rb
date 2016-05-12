class SendMessageJob < Job
  def perform(message_id)
    message = Message.find(message_id)
    MessageService.new(message).send_now

    ping_pusher(message)
  end

  private

    def ping_pusher(message)
      notification = message.notification
      if notification
        PusherJob.perform_async(
          "notification",
          "notification-#{notification.id}",
          {
            ok: message.success,
            recipient: (message.user || message.channel),
            sent: notification.messages.sent.count
          }.to_json
        )
      end
    end
end
