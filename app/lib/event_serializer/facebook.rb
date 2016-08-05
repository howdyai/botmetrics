class EventSerializer::Facebook
  AVAILABLE_TYPES = {
                      message: 'Message',
                      echo: 'MessageEchoes'
                      #postback: 'MessagingPostbacks',
                      #optin: 'MessagingOptins',
                      #account_linking: 'AccountLinking',
                      #delivery: 'MessageDeliveries',
                      #read: 'MessageReads'
                    }

  def initialize(data)
    raise 'SuppliedOptionIsNil' if data.nil?
    raise 'InvalidDataSupplied' unless data.is_a?(Hash) && symbolized_data(data)[:entry].present?
    @data = data[:entry]
  end

  def serialize
    @events = []
    if @data.is_a?(Hash)
      @events << serializer(prepare_event(@data)).serialize
    elsif @data.is_a?(Array)
      @data.each do |entry|
        prepare_event(entry)
      end
    end
    @events
  end

private

  def prepare_event(entry)
    if entry[:messaging].is_a?(Hash)
      @events << serializer(symbolized_data(entry[:messaging])).serialize
    elsif entry[:messaging].is_a?(Array)
      entry[:messaging].each do |event|
        @events << serializer(event).serialize
      end
    end
  end

  def symbolized_data(data)
    data.symbolize_keys! unless data.is_a? Array
    data.each do |_key, v|
      if v.is_a? Hash
        symbolized_data(v) if v.is_a? Hash
      elsif v.is_a? Array
        v.each { |val| symbolized_data(val) }
      end
    end
  end

  def event_type(data)
    type = data.select { |type| AVAILABLE_TYPES.keys.include? type }.keys.first
    raise 'IncorrectEventType' if type.nil?

    return :echo if type == :message && data.dig(:message, :is_echo)
    type
  end

  def serializer(data)
    "EventSerializer::Facebook::#{AVAILABLE_TYPES[event_type(data)]}".constantize.new(data)
  end
end
