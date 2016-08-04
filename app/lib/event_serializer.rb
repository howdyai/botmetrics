class EventSerializer
  def initialize(provider, data)
    @provider = EventSerializer.const_get(provider.to_s.camelize).new(data)
  end

  def serialize
    @provider.serialize
  end
end
