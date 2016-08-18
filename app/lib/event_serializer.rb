class EventSerializer
  def initialize(provider, data, bi_uid)
    raise 'NoOptionSupplied' if provider.nil? || data.nil?
    @provider = "EventSerializer::#{provider.to_s.camelize}".constantize.new(data, bi_uid)
  end

  def serialize
    @provider.serialize
  end
end
