class EventSerializer::Facebook::MessagingReferrals < EventSerializer::Facebook::Base
  private
  def data
    {
      event_type: 'messaging_referrals',
      is_for_bot: false,
      is_im: false,
      is_from_bot: false,
      provider: 'facebook',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    {
      referral: @data.dig(:referral)
    }
  end
end
