class EventSerializer::Kik::Message < EventSerializer::Kik::Base
  private
  def data
    {
      event_type: 'message',
      is_for_bot: @data[:mention].present?,
      is_from_bot: false,
      text: @data[:body],
      provider: 'kik',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    event_attributes = {
      chat_id: @data[:chatId],
      id: @data[:id],
      sub_type: @data[:type],
    }
    event_attributes.merge!(secondary_attributes)
    event_attributes
  end

  def secondary_attributes
    data = {}
    @data.except!(:chatId, :id, :type, :body, :timestamp, :mention)
    @data.each { |k, v| data[k&.to_s&.underscore&.to_sym] = v }
    data
  end
end
