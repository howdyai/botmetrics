# frozen_string_literal: true

class PostMessageToFacebookService
  def initialize(message, token)
    @message = message
    @token = token
  end

  def call
    facebook_client.call('me/messages', 'POST', options)
  end

  private
  attr_reader :message, :token

  def facebook_client
    @_facebook_client ||= Facebook.new(token)
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
