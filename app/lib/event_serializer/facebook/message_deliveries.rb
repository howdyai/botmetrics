class EventSerializer::Facebook::MessageDeliveries
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: message, recip_info: recip_info }
  end

private

  def messaging_postback
    {
      event_type: 'messaging_postbacks',
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      provider: 'facebook',
      event_attributes: event_attributes
    }
  end

  def event_attributes
    { payload: @data.dig(:postback, :payload) }
  end

  def recip_info
    {
      sender_id: @data.dig(:sender, :id),
      recipient_id: @data.dig(:recipient, :id)
    }
  end
end
