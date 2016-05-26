class WebhookValidate
  def initialize(bot_id)
    @bot = Bot.find(bot_id)
    @code = nil
  end

  def call
    if webhook_is_legit?
      PusherJob.perform_async channel_name, message, { "ok": true }.to_json
    else
      PusherJob.perform_async channel_name, message, { "ok": false }.to_json
    end
  end

  private

    attr_reader :bot, :code

    def webhook_is_legit?
      ping_webhook! && update_webhook_status
    end

    def ping_webhook!
      @code = Webhook.ping(bot.id).status
    end

    def update_webhook_status
      bot.update(webhook_status: successfully_pinged?)

      successfully_pinged?
    end

    def successfully_pinged?
      @_successfully_pinged ||= [200, 201, 202].include?(code)
    end

    def channel_name
      "webhook-validate-bot".freeze
    end

    def message
      "webhook-validate-bot-#{bot.id}"
    end
end
