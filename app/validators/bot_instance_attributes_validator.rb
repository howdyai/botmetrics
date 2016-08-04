class BotInstanceAttributesValidator < ActiveModel::Validator
  def validate(record)
    if record.state == 'enabled' && record.provider == 'slack'
      if record.instance_attributes['team_id'].blank?
        record.errors[:instance_attributes] << "team_id can't be blank"
      end
      if record.instance_attributes['team_url'].blank?
        record.errors[:instance_attributes] << "team_url can't be blank"
      end
      if record.instance_attributes['team_name'].blank?
        record.errors[:instance_attributes] << "team_name can't be blank"
      end
    elsif record.state == 'enabled' && record.provider == 'facebook'
      if record.instance_attributes['name'].blank?
        record.errors[:instance_attributes] << "name can't be blank"
      end
    end
  end
end
