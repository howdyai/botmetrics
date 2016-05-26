class InitDefaultEmailPreferencesDailyReports < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.email_preferences[:daily_reports] ||= '1'
      user.save(validate: false)
    end
  end
end
