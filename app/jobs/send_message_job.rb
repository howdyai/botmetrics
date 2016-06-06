class SendMessageJob < Job
  def perform(message_id)
    MessageService.new(message_id).send_now
  end
end
