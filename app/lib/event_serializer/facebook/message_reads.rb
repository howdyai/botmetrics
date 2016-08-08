class EventSerializer::Facebook::MessageReads < EventSerializer::Facebook::Base
  protected
  def watermark
    Time.at(@data.dig(:read, :watermark).to_f / 1000)
  end

  private
  def data
    {
      event_type: 'message_reads',
      watermark: watermark
    }
  end
end
