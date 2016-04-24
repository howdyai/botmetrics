class BotInstanceAttributesValidator < ActiveModel::Validator
  def validate(record)
    if record.state != 'pending' && record.provider == 'slack'
      if record.instance_attributes['team_id'].blank?
        record.errors[:instance_attributes] << "team_id can't be blank"
      end
      if record.instance_attributes['team_url'].blank?
        record.errors[:instance_attributes] << "team_url can't be blank"
      end
      if record.instance_attributes['team_name'].blank?
        record.errors[:instance_attributes] << "team_name can't be blank"
      end
    end
  end
end
