class NotifyAdminOnSlackJob < Job
  def perform(user_id, payload)
    slack_hook = ENV['BOTMETRICS_SLACK_HOOK']
    slack_channel = ENV['BOTMETRICS_SLACK_CHANNEL']
    return if slack_hook.blank?

    payload = if payload.is_a?(Array)
             payload.join("\n")
           elsif payload.is_a?(String)
             payload
           elsif payload.is_a?(Hash)
             payload
           else
             raise RuntimeError.new("Unexpected argument for NotifyAdminOnSlackJob: #{messages.inspect}")
           end

    user = User.find(user_id)

    attachments = {}

    if payload.is_a?(Hash)
      payload.merge!({
        'Email' => user.email,
        'Full Name' => user.full_name,
        'Timezone' => user.timezone
      })

      text = payload.delete(:title) || payload.delete('title')
      attachments[:title] = text
      attachments[:fallback] = text
      attachments[:color] = payload.delete(:color) || payload.delete('color') || 'good'
      attachments[:fields] = payload.inject([]) { |f, (k,v)| f << { title: k.to_s.split(/[ _]/).map(&:capitalize).join(' '), value: v, short: true }; f }
    elsif payload.is_a?(String)
      text = payload
    end

    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360
    }

    params = {
      channel: slack_channel,
      username: 'BotmetricsBot',
      icon_emoji: ':chart_with_upwards_trend:',
      attachments: [attachments]
    }

    params[:text] = text if attachments.blank?

    opts[:body] = URI.encode_www_form(payload: params.to_json)
    opts[:headers] = { "Content-Type" => "application/x-www-form-urlencoded" }

    connection = Excon.new(slack_hook, opts)

    response = connection.request(method: 'POST')
    response.body == 'ok'
  end
end
