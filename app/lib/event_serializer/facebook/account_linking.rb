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
end
