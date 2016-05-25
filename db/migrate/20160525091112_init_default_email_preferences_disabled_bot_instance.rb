class InitDefaultEmailPreferencesDisabledBotInstance < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.email_preferences[:disabled_bot_instance] ||= '1'
      user.save(validate: false)
    end
  end
end
