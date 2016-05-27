class SendEventToWebhookJob < Job
  def perform(bot_id, event_id)
    event = Event.find event_id
    Webhook.new(bot_id, event).deliver
  end
end
