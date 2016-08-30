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
      recipient: { id: message.user },
      message:   { text: message.text }
    }
  end
end
