class EventSerializer::Facebook::MessageDeliveries < EventSerializer::Facebook::Base
  protected
  def watermark
    Time.at(@data.dig(:delivery, :watermark).to_f / 1000)
  end

  private
  def data
    {
      event_type: 'message_deliveries',
      watermark: watermark
    }
  end
end
