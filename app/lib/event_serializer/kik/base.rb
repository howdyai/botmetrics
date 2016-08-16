class EventSerializer::Kik::Base
  def initialize(data)
    raise 'Supplied Option Is Nil' if data.nil?
    @data = data
  end

  def serialize
    { data: data, recip_info: recip_info }
  end

  protected
  def recip_info
    {
      from: @data[:from],
      to: @data[:to]
    }
  end

  def timestamp
    Time.at(@data[:timestamp].to_f / 1000)
  end
end
