class EventSerializer::Facebook::Message
  def initialize(data)
    @data = data
  end

  def serialize
    serialized = @data.dig(:message, :is_echo) ? echo : message
    { data: serialized, recip_info: recip_info }
  end

private

  def echo
    base_event_attributes.merge(event_type: 'message_echoes')
  end

  def message
    base_event_attributes.merge(event_type: 'message')
  end

  def base_event_attributes
    {
      is_for_bot: true,
      is_im: true,
      text: text,
      provider: 'facebook',
      event_attributes: event_attributes
    }
  end

  def event_attributes
    {
      attachments: attachments,
      delivered: false,
      read: false,
      mid: @data.dig(:message, :mid),
      seq: @data.dig(:message, :seq)
    }
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
