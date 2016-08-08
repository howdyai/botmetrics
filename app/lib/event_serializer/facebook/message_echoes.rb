class EventSerializer::Facebook::MessageEchoes < EventSerializer::Facebook::Base
  private
  def data
    {
      event_type: 'message',
      is_for_bot: false,
      is_im: true,
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
end
