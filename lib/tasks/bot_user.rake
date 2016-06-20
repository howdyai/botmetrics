namespace :botmetrics do
  desc "backfill_bot_users"
  task :backfill_bot_users => :environment do
    Event.where(is_for_bot: true).find_each do |event|
      user = event.user
      BotUser.transaction do
        user.increment!(:bot_interaction_count)
        user.update_attribute(:last_interacted_with_bot_at, event.created_at)
      end

      puts "finished event id: #{event.id}"
    end
  end
end
