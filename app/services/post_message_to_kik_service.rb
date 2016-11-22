# frozen_string_literal: true

class PostMessageToKikService
  def initialize(message, token, uid)
    @message = message
    @token = token
    @uid = uid
  end

  def call
    kik_client.call('message', 'POST', options)
  end

  private
  attr_reader :message, :token, :uid

  def kik_client
    @_kik_client ||= Kik.new(token, uid)
  end

  def options
    {
      messages: [
        {
          body: message.text,
          to: message.user,
          type: 'text'
        }
      ]
    }
  end
end

