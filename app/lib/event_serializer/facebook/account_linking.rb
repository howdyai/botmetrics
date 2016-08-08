class EventSerializer::Facebook::AccountLinking < EventSerializer::Facebook::Base
  private
  def data
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
end
