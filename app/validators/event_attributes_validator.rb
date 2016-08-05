class EventAttributesValidator < ActiveModel::Validator
  def validate(record)
    if (record.event_type == 'message' || record.event_type == 'message_reaction') && record.provider == 'slack'
      if record.event_attributes['channel'].blank?
        record.errors[:event_attributes] << "channel can't be blank"
      end
      if record.event_attributes['timestamp'].blank?
        record.errors[:event_attributes] << "timestamp can't be blank"
      end
    end
  end
end
