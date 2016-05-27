# frozen_string_literal: true

class Webhook
  def self.ping(bot_id, options = {})
    bot = find_bot_by(bot_id)

    options[:body] = payload('hook' => dummy_payload)

    Excon.post bot.webhook_url, default_options.merge(options)
  end

  def self.deliver(bot_id, event, options = {})
    bot = find_bot_by(bot_id)
    response = nil

    options[:body] = payload('hook' => { bot_uid: bot.uid }, 'event' => event.to_json)

    elapsed_time = Stopwatch.record do
      response = Excon.post(bot.webhook_url, default_options.merge(options))
    end

    log_webhook_execution(bot, elapsed_time, response.status, event.event_attributes)

    response
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
    private_class_method :default_options

    def self.payload(params)
      URI.encode_www_form('payload' => params.to_json)
    end
    private_class_method :payload

    def self.find_bot_by(bot_id)
      Bot.find bot_id
    end
    private_class_method :find_bot_by

    def self.log_webhook_execution(bot, elapsed_time, code, event_attrs)
      bot.webhook_events.create(
        elapsed_time: elapsed_time,
        code: code,
        payload: { channel_uid: event_attrs['channel'], timestamp: event_attrs['timestamp'] }
      )
    end
    private_class_method :log_webhook_execution

    def self.dummy_payload
      {
        type: 'ping',
        user_uid: 'user_uid',
        channel_uid: SecureRandom.hex(4),
        team_uid: 'team_uid',
        im: true,
        text: 'hello world',
        relax_bot_uid: 'URELAXBOT',
        timestamp: Time.at(rand * Time.now.to_i).to_i,
        provider: 'slack/kik/facebook/telegram',
        event_timestamp: Time.at(rand * Time.now.to_i).to_i,
      }
    end
    private_class_method :dummy_payload
end
