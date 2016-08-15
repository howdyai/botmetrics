class EventSerializer::Kik::Message < EventSerializer::Kik::Base
  private
  def data
    {
      event_type: 'message',
      is_for_bot: @data[:mention].present?,
      is_im: @data[:participants].present? && @data[:participants].count > 1,
      is_from_bot: !@data[:mention].present?,
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
    @data.except(:chatId, :id, :type, :body, :timestamp, :mention)
  end
end
