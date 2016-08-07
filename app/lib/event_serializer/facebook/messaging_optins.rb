class EventSerializer::Facebook::MessagingOptins
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: messaging_optin, recip_info: recip_info }
  end

private

  def messaging_optin
    {
      event_type: 'messaging_optins',
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      provider: 'facebook',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    { optin: @data.dig(:optin) }
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
