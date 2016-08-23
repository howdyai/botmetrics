class DashboardRegexValidator < ActiveModel::Validator
  def validate(record)
    if record.dashboard_type == 'custom'
      begin
        r = Regexp.new(record.regex)
      rescue RegexpError => e
        record.errors[:regex] << e.message
      end
    end
  end
end
