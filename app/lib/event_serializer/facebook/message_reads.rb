class EventSerializer::Facebook::MessageReads
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: message_read, recip_info: recip_info }
  end

private

  def message_read
    {
      event_type: 'message_reads',
      watermark: watermark
    }
  end

  def recip_info
    {
      sender_id: @data.dig(:sender, :id),
      recipient_id: @data.dig(:recipient, :id)
    }
  end

  def watermark
    watermark = @data.dig(:read, :watermark).to_s
    if watermark.split('').count == 13
      Time.at(watermark.to_f / 1000)
    elsif watermark.split('').count == 10
      Time.at(watermark.to_f)
    end
  end
end
