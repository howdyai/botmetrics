class ValidateWebhookAndUpdatesJob < Job
  def perform(bot_id)
    ValidateWebhookAndUpdatesService.new(bot_id).call
  end
end
