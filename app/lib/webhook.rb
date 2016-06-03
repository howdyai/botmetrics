# frozen_string_literal: true

class Webhook
  def initialize(bot_id, relax_event_json = nil, options: {})
    @bot = find_bot_by(bot_id)
    @relax_event = JSON.parse(relax_event_json) if relax_event_json.present?
    @options = options
  end

  def ping
    options[:body] = payload(dummy_payload.to_json)
    Excon.post bot.webhook_url, default_options.merge(options)
  end

  def deliver
    response = nil

    options[:body] = payload(@relax_event.to_json)

    elapsed_time = Stopwatch.record do
      response = Excon.post(bot.webhook_url, default_options.merge(options))
    end

    log_webhook_execution(bot, elapsed_time, response.status, @relax_event)

    response
  end

  def validate
    [200, 201, 202].include? ping.status
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
        'X-BotMetrics-Event' => 'deliver',
      },
    }
  end

  def payload(params)
    URI.encode_www_form('payload' => params)
  end

  def find_bot_by(bot_id)
    Bot.find bot_id
  end

  def log_webhook_execution(bot, elapsed_time, code, event_attrs)
    bot.webhook_events.create!(
      elapsed_time: elapsed_time,
      code: code,
      payload: { channel_uid: event_attrs['channel_uid'], timestamp: event_attrs['timestamp'] }
    )
  end

  def dummy_payload
    {
      type: 'message_new',
      user_uid: 'user_uid',
      channel_uid: SecureRandom.hex(4),
      team_uid: 'team_uid',
      im: true,
      text: 'hello world',
      relax_bot_uid: 'URELAXBOT',
      timestamp: Time.at(rand * Time.now.to_i).to_i,
      provider: bot.provider,
      event_timestamp: Time.at(rand * Time.now.to_i).to_i,
    }
  end
end
