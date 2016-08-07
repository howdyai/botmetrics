class EventSerializer::Facebook::MessageEchoes
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
      is_for_bot: false,
      is_im: false,
      is_from_bot: true,
      text: @data.dig(:message, :text),
      provider: 'facebook',
      created_at: timestamp,
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

  def timestamp
    timestamp = @data[:timestamp].to_s
    if timestamp.split('').count == 13
      Time.at(timestamp.to_f / 1000)
    elsif timestamp.split('').count == 10
      Time.at(timestamp.to_f)
    end
  end
end
