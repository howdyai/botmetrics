class EventSerializer::Facebook
  AVAILABLE_TYPES = { message: 'Message', postback: 'MessagingPostbacks',
                      optin: 'MessagingOptins', account_linking: 'AccountLinking',
                      delivery: 'MessageDeliveries', read: 'MessageReads',  echo: 'MessageEchoes' }

  def initialize(data)
    @data = data
  end

  def serialize
    serializer(@data).serialize
  end

private

  def event_type(data)
    type = data.select { |type| AVAILABLE_TYPES.keys.include? type }.keys.first
    return :echo if type == :message && data.dig(:message, :is_echo)
    type
  end

  def serializer(data)
    EventSerializer::Facebook.const_get(AVAILABLE_TYPES[event_type(data)]).new(data)
  end
end
