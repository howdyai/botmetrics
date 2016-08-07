class EventSerializer::Facebook::AccountLinking
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: account_linking, recip_info: recip_info }
  end

private

  def account_linking
    {
      event_type: 'account_linking',
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      provider: 'facebook',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    { account_linking: @data.dig(:account_linking) }
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
