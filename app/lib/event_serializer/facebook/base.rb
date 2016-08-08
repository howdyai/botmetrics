class EventSerializer::Facebook::Base
  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    @data = data
  end

  def serialize
    { data: data, recip_info: recip_info }
  end

  protected
  def recip_info
    {
      sender_id: @data.dig(:sender, :id),
      recipient_id: @data.dig(:recipient, :id)
    }
  end

  def timestamp
    Time.at(@data[:timestamp].to_f / 1000)
  end
end
