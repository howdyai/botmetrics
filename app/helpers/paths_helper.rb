module PathsHelper
  def formatted_event(event)
    case event.event_type
      when 'user-added' then 'User Signed Up'
      when 'message', 'message:image-uploaded', 'message:link-uploaded', 'message:location-sent', 'message:video-uploaded'
        if (attachments = event.event_attributes['attachments']).present?
          "Message with Attachments: <code>#{attachments}</code>"
        else
          event.text.to_s
        end
      when 'messaging_postbacks' then "Clicked Button with payload: <code>#{event.event_attributes['payload']}</code>"
      else ''
    end
  end
end
