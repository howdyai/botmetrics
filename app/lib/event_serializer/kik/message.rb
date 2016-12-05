class EventSerializer::Kik::Message < EventSerializer::Kik::Base
  private
  attr_reader :bi_uid

  def data
    {
      event_type: event_type,
      is_for_bot: @data[:from] != bi_uid,
      is_from_bot: @data[:from] == bi_uid,
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

  def event_type
    case @data[:type]
      when 'text' then 'message'
      when 'picture'        then 'message:image-uploaded'
      when 'video'          then 'message:video-uploaded'
      when 'link'           then 'message:link-uploaded'
      when 'sticker'        then 'message:sticker-uploaded'
      when 'scan-data'      then 'message:scanned-data'
      when 'friend-picker'  then 'message:friend-picker-chosen'
      when 'start-chatting' then 'message:start-chatting'
      when 'is-typing'      then 'message:is-typing'
      else 'message'
    end
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
