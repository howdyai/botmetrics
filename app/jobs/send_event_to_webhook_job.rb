class SendEventToWebhookJob < Job
  def perform(bot_id, event_json)
    Webhook.new(bot_id, event_json).deliver
  end
end
