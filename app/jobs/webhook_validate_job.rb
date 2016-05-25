class WebhookValidateJob < Job
  def perform(bot_id)
    WebhookValidate.new(bot_id).call
  end
end
