class SendEventToWebhookJob < Job
  def perform(bot_id, event_id)
    SendEventToWebhook.new(bot_id, event_id).call
  end
end
