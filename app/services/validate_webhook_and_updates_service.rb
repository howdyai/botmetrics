# frozen_string_literal: true

class ValidateWebhookAndUpdatesService
  def initialize(bot_id)
    @bot = Bot.find(bot_id)
  end

  def call
    webhook_is_valid = Webhook.new(bot.id).validate

    bot.update(webhook_status: webhook_is_valid)

    PusherJob.perform_async(
      'webhook-validate-bot',
      "webhook-validate-bot-#{bot.id}",
      { 'ok': webhook_is_valid }.to_json
    )
  end

  private

    attr_reader :bot
end
