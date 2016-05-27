class SendEventToWebhook
  def initialize(bot_id, event_id)
    @bot_id = bot_id
    @event = Event.find event_id
  end

  def call
    Webhook.new(bot_id, event).deliver
  end

  private

    attr_reader :bot_id, :event
end
