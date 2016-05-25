class InitDefaultEmailPreferences < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.email_preferences[:created_bot_instance] ||= '1'
      user.save(validate: false)
    end
  end
end
