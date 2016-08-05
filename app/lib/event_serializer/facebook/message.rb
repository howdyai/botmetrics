class EventSerializer::Facebook::Message
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: message, recip_info: recip_info }
  end

private

  def message
    {
      event_type: 'message',
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      text: text,
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
    event_attributes.merge!(attachments: attachments) if attachments&.any?
    event_attributes.merge!(quick_reply: quick_reply) if quick_reply.present?
    event_attributes
  end

  def text
    text = @data.dig(:message, :text)
    if text.present?
      text
    else
      @data.dig(:message, :quick_reply, :payload)
    end
  end

  def attachments
    @data.dig(:message, :attachments)
  end

  def quick_reply
    if @data.dig(:message, :text)
      @data.dig(:message, :quick_reply, :payload)
    else
      true
    end
  end

  def recip_info
    {
      sender_id: @data.dig(:sender, :id),
      recipient_id: @data.dig(:recipient, :id)
    }
  end
end
