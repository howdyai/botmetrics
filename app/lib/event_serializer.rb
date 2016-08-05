class EventSerializer
  def initialize(provider, data)
    raise 'NoOptionSupplied' if provider.nil? || data.nil?
    @provider = "EventSerializer::#{provider.to_s.camelize}".constantize.new(data)
  end

  def serialize
    @provider.serialize
  end
end
