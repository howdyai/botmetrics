class EventSerializer
  def initialize(provider, data)
    @provider = "EventSerializer::#{provider.to_s.camelize}".constantize.new(data)
  end

  def serialize
    @provider.serialize
  end
end
