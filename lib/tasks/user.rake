namespace :botmetrics do
  desc "invite_users_to_slack"
  task :invite_to_users_to_slack => :environment do
    User.find_each do |user|
      InviteToSlackJob.new.perform(user.id)
      user.reload
      puts "invited user: #{user.email} #{user.invited_to_slack_at}"
    end
  end
end

