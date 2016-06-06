class SendMessageJob < Job
  def perform(message_id)
    message = Message.find message_id
    MessageService.new(message).send_now
  end
end
