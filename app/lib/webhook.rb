# frozen_string_literal: true

class Webhook

  def initialize(bot_id, event = nil, options: {})
    @bot = find_bot_by(bot_id)
    @event = event if event
    @options = options
  end

  def ping
    options[:body] = payload('hook' => dummy_payload)

    Excon.post bot.webhook_url, default_options.merge(options)
  end

  def deliver
    response = nil

    options[:body] = payload('hook' => { bot_uid: bot.uid }, 'event' => event.to_json)

    elapsed_time = Stopwatch.record do
      response = Excon.post(bot.webhook_url, default_options.merge(options))
    end

    log_webhook_execution(bot, elapsed_time, response.status, event.event_attributes)

    response
  end

  private

    attr_reader :bot, :event, :options

    def default_options
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

    def payload(params)
      URI.encode_www_form('payload' => params.to_json)
    end

    def find_bot_by(bot_id)
      Bot.find bot_id
    end

    def log_webhook_execution(bot, elapsed_time, code, event_attrs)
      bot.webhook_events.create(
        elapsed_time: elapsed_time,
        code: code,
        payload: { channel_uid: event_attrs['channel'], timestamp: event_attrs['timestamp'] }
      )
    end

    def dummy_payload
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
end
