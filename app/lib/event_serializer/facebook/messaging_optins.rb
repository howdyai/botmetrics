class EventSerializer::Facebook::MessagingOptins < EventSerializer::Facebook::Base
  private
  def data
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
end
