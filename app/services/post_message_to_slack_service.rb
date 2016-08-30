# frozen_string_literal: true

class PostMessageToSlackService
  def initialize(message, token)
    @message = message
    @token = token
  end

  def channel
    return message_channel if message_user.blank?

    im_response['ok'] ? im_response['channel']['id'] : message_log_response(im_response)
  end

  def call
    slack_client.call('chat.postMessage', 'POST', options)
  end

  private
  attr_reader :message, :token

  delegate :channel, :user, :log_response, :text, :attachments, to: :message, prefix: true

  def slack_client
    @_slack_client ||= Slack.new(token)
  end

  def im_response
    @_im_response ||= slack_client.call('im.open', 'POST', user: message_user)
  end

  def options
    {
      as_user: 'true',
      channel: channel,
      text: message_text,
      attachments: message_attachments,
      mrkdwn: true,
    }.delete_if { |_, v| v.blank? }
  end
end
