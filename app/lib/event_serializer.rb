class EventSerializer
  def initialize(bot, data)
    @bot = "EventSerializer::#{bot.to_s.camelize}".constantize.new(data)
  end

  def serialize
    @bot.serialize
  end
end
