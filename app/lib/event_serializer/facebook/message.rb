class EventSerializer::Facebook::Message
  def initialize(data)
    @data = data
  end

  def serialize
    @data.dig(:message, :is_echo) ? echo : message
  end

private

  def echo
    base_event_attributes.merge(event_type: 'message_echoes')
  end

  def message
    base_event_attributes.merge(event_type: 'message', quick_reply: quick_reply)
  end

  def base_event_attributes
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
end
