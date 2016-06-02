class MessageService
  def initialize(message)
    @message      = message
    @bot_instance = message.bot_instance
  end

  def send_now
    message.update(sent_at: Time.current)

    return false if !@bot_instance.state == 'enabled'
    return false if channel.blank?

    response = slack.call('chat.postMessage', 'POST', slack_opts)

    if response['ok']
      message.update(success: true, response: response)
      response['ok']
    else
      error!(response)
    end
  end

  private

    attr_accessor :message, :bot_instance

    def slack
      @_slack ||= Slack.new(bot_instance.token)
    end

    def channel
      @_channel ||=
        if message.user.present?
          im_response = slack.call('im.open', 'POST', user: message.user)
          im_response['ok'] ? im_response['channel']['id'] : error!(im_response)
        else
          message.channel
        end
    end

    def slack_opts
      {
        as_user: 'true',
        channel: channel,
        text: message.text,
        attachments: message.attachments,
        mrkdwn: true
      }.delete_if { |_, v| v.blank? }
    end

    def error!(response)
      message.update(success: false, response: response)
      nil
    end
end
