class EventSerializer::Facebook::MessagingPostbacks < EventSerializer::Facebook::Base
  private
  def data
    {
      event_type: 'messaging_postbacks',
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      provider: 'facebook',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    {
      payload: @data.dig(:postback, :payload),
      referral: @data.dig(:postback, :referral)
    }
  end
end
