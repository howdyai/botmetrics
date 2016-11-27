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

      available_sub_types = %w(text link picture video start-chatting scan-data sticker is-typing friend-picker)
      if !available_sub_types.include?(record.event_attributes['sub_type'])
        record.errors[:event_attributes] << "incorrect sub_type"
      end
    end
  end
end
