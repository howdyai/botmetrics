class EventSerializer::Facebook::Message < EventSerializer::Facebook::Base
  private
  def data
    {
      event_type: event_type,
      is_for_bot: true,
      is_im: true,
      is_from_bot: false,
      text: text,
      provider: 'facebook',
      created_at: timestamp,
      event_attributes: event_attributes
    }
  end

  def event_attributes
    event_attributes = {
      mid: @data.dig(:message, :mid),
      seq: @data.dig(:message, :seq)
    }
    event_attributes.merge!(attachments: attachments) if attachments&.any?
    event_attributes.merge!(quick_reply: quick_reply) if quick_reply.present?
    event_attributes
  end

  def text
    text = @data.dig(:message, :text)
    if text.present?
      text
    else
      @data.dig(:message, :quick_reply, :payload)
    end
  end

  def attachments
    @data.dig(:message, :attachments)
  end

  def event_type
    _attachments = attachments
    event_type = 'message'

    if _attachments&.any?
      event_type = case attachments[0][:type]
                     when 'image'    then 'message:image-uploaded'
                     when 'video'    then 'message:video-uploaded'
                     when 'audio'    then 'message:audio-uploaded'
                     when 'file'     then 'message:file-uploaded'
                     when 'location' then 'message:location-sent'
                     else 'message'
                   end
    end

    event_type
  end

  def quick_reply
    if @data.dig(:message, :text)
      @data.dig(:message, :quick_reply, :payload)
    else
      true
    end
  end
end
