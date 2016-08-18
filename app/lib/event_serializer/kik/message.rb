class EventSerializer::Kik::Message < EventSerializer::Kik::Base
  private
  attr_reader :bi_uid

  def data
    {
      event_type: 'message',
      is_for_bot: @data[:from] != bi_uid,
      is_from_bot: false,
      is_im: @data[:participants].count == 1 && @data[:participants].first == bi_uid,
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
    @data.except!(:chatId, :id, :type, :body, :timestamp, :mention)
    snakecase_keys
  end

  def snakecase_keys
    data = {}
    @data.each { |k, v| data[k.to_s.underscore.to_sym] = v }
    data
  end
end
