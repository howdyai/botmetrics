class BotUserIdValidator < ActiveModel::Validator
  def validate(record)
    case record.provider
    when 'slack'
      if record.bot_user_id.blank? && (record.event_type == 'message' || record.event_type == 'message_reaction')
        record.errors[:bot_user_id] << "can't be blank"
      end
    when 'facebook'
      if record.bot_user_id.blank?
        record.errors[:bot_user_id] << "can't be blank"
      end
    end
  end
end
