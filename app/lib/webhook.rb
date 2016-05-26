class Webhook
  def self.ping(bot_id, options = {})
    bot = find_bot_by(bot_id)

    options[:body] = payload('hook' => { bot_uid: bot.uid })

    Excon.post bot.webhook_url, default_options.merge(options)
  end

  private

    def self.default_options
      {
        omit_default_port: true,
        idempotent: true,
        retry_limit: 6,
        read_timeout: 360,
        connect_timeout: 360,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'X-BotMetrics-Event' => 'ping',
        },
      }
    end

    def self.payload(params)
       URI.encode_www_form('payload' => params.to_json)
    end

    def self.find_bot_by(bot_id)
      Bot.find bot_id
    end
end
