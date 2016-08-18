class EventSerializer::Kik
  def initialize(data, bi_uid)
    raise 'Supplied Option Is Nil' if data.nil?
    raise 'Invalid Data Supplied' unless data.is_a?(Array)
    @data = symbolized_data(data)
    @bi_uid = bi_uid
    @events = []
  end

  def serialize
    @data.each do |event|
      @events << serializer(event).serialize
    end
    @events
  end

  private
  attr_reader :bi_uid

  def symbolized_data(data)
    hashes = data.grep(Hash)
    hashes.each do |hash|
      hash.symbolize_keys!
      hash.each do |k, v|
        next unless v.respond_to?(:grep)
        if v.grep(Hash).any?
          symbolized_data(v)
        elsif v.is_a?(Hash)
          hash[k].symbolize_keys!
        end
      end
    end
  end

  def serializer(data)
    EventSerializer::Kik::Message.new(data, bi_uid)
  end
end
