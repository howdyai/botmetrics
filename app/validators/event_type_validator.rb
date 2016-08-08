class EventTypeValidator < ActiveModel::Validator
  SLACK_EVENT_TYPES = %w(user_added bot_disabled added_to_channel message message_reaction)
  FACEBOOK_EVENT_TYPES = %w(message messaging_optins messaging_postbacks account_linking)

  def validate(record)
    case record.provider
    when 'slack'
      if SLACK_EVENT_TYPES.index(record.event_type).nil?
        record.errors[:event_type] << "invalid event type"
      end
    when 'facebook'
      if FACEBOOK_EVENT_TYPES.index(record.event_type).nil?
        record.errors[:event_type] << "invalid event type"
      end
    end
  end
end
