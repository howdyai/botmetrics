class EventAttributesValidator < ActiveModel::Validator
  def validate(record)
    if (record.event_type == 'message' || record.event_type == 'message_reaction') && record.provider == 'slack'
      if record.event_attributes['channel'].blank?
        record.errors[:event_attributes] << "channel can't be blank"
      end
      if record.event_attributes['timestamp'].blank?
        record.errors[:event_attributes] << "timestamp can't be blank"
      end
    elsif (record.event_type == 'message') && record.provider == 'facebook'
      if record.event_attributes['mid'].blank?
        record.errors[:event_attributes] << "mid can't be blank"
      end
      if record.event_attributes['seq'].blank?
        record.errors[:event_attributes] << "seq can't be blank"
      end
    elsif (record.event_type == 'message') && record.provider == 'kik'
      if record.event_attributes['id'].blank?
        record.errors[:event_attributes] << "id can't be blank"
      end
      if record.event_attributes['chat_id'].blank?
        record.errors[:event_attributes] << "chat_id can't be blank"
      end
    end
  end
end
