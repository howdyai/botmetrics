class WebhookValidate
  def initialize(bot_id)
    @bot = Bot.find(bot_id)
    @code = nil
  end

  def call
    if webhook_is_legit?
      PusherJob.perform_async(channel_name, message, %<{"ok":true}>)
    else
      PusherJob.perform_async(channel_name, message, %<{"ok":false}>)
    end
  end

  private

    attr_reader :bot
    attr_accessor :code

    def webhook_is_legit?
      log_webhook_history(ping_webhook!) && successfully_pinged?
    end

    def ping_webhook!
      timely do
        @code = Excon.get(bot.webhook_url).status
      end
    end

    def log_webhook_history(elapsed_time)
      bot.webhook_histories.create(code: code, elapsed_time: elapsed_time)
    end

    def successfully_pinged?
      [200, 201, 202].include?(code)
    end

    def timely
      start = Time.current
      yield 
      Time.current - start
    end

    def channel_name
      "webhook-validate-bot".freeze
    end

    def message
      "webhook-validate-bot-#{bot.id}"
    end
end
