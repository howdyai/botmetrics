class EventSerializer::Facebook
  AVAILABLE_TYPES = { message: 'Message', postback: 'MessagingPostbacks',
                      optin: 'MessagingOptins', account_linking: 'AccountLinking',
                      delivery: 'MessageDeliveries', read: 'MessageReads' }

  def initialize(data)
    @data = data
  end

  def serialize
    serializer(@data).serialize
  end

private

  def event_type(data)
    data.select { |type| AVAILABLE_TYPES.keys.include? type }.keys.first
  end

  def serializer(data)
    raise StandardError unless event_type(data).present?
    "EventSerializer::Facebook::#{AVAILABLE_TYPES[event_type(data)]}".constantize.new(data)
  end
end
