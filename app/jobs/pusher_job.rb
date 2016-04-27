class PusherJob < Job
  def perform(channel, message, payload)
    Pusher[channel].trigger message, message: payload
  end
end
