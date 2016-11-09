class EventTypeValidator < ActiveModel::Validator
  SLACK_EVENT_TYPES = %w(user_added bot_disabled added_to_channel message message_reaction)
  FACEBOOK_EVENT_TYPES = %w(message messaging_optins messaging_postbacks account_linking messaging_referrals)
  KIK_EVENT_TYPES = %w(message)

  def validate(record)
    case record.provider
    when 'slack'
      if !SLACK_EVENT_TYPES.include?(record.event_type)
        record.errors[:event_type] << "invalid event type"
      end
    when 'facebook'
      if !FACEBOOK_EVENT_TYPES.include?(record.event_type)
        record.errors[:event_type] << "invalid event type"
      end
    when 'kik'
      if !KIK_EVENT_TYPES.include?(record.event_type)
        record.errors[:event_type] << "invalid event type"
      end
    end
  end
end
