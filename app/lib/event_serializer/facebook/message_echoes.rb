class EventSerializer::Facebook::MessageEchoes
  def initialize(data)
    @data = data
  end

  def serialize
    { data: message, recip_info: recip_info }
  end

private

  def message
    {
      event_type: 'message_echoes',
      is_for_bot: true,
      is_im: true,
      text: @data.dig(:message, :text),
      provider: 'facebook',
      event_attributes: event_attributes
    }
  end

  def event_attributes
    event_attributes = {
      delivered: false,
      read: false,
      mid: @data.dig(:message, :mid),
      seq: @data.dig(:message, :seq)
    }
    event_attributes.merge(attachments: attachments) if attachments&.any?
    event_attributes
  end

  def attachments
    @data.dig(:message, :attachments)
  end

  def recip_info
    {
      sender_id: @data.dig(:sender, :id),
      recipient_id: @data.dig(:recipient, :id)
    }
  end
end
