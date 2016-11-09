class EventSerializer::Facebook
  AVAILABLE_TYPES = {
                      message: 'Message',
                      echo: 'MessageEchoes',
                      postback: 'MessagingPostbacks',
                      optin: 'MessagingOptins',
                      account_linking: 'AccountLinking',
                      delivery: 'MessageDeliveries',
                      read: 'MessageReads',
                      referral: 'MessagingReferrals'
                    }

  def initialize(data, bi_uid)
    raise 'Supplied Option Is Nil' if data.nil?
    raise 'Invalid Data Supplied' unless data.is_a?(Hash) && symbolized_data(data)[:entry].present?
    @data = data[:entry]
    @bi_uid = bi_uid
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
    return unless data.is_a?(Hash)

    data.symbolize_keys!

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
    raise 'Incorrect Event Type' if type.nil?

    return :echo if type == :message && data.dig(:message, :is_echo)
    type
  end

  def serializer(data)
    "EventSerializer::Facebook::#{AVAILABLE_TYPES[event_type(data)]}".constantize.new(data)
  end
end
