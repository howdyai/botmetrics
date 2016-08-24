namespace :botmetrics do
  desc "backfill_mixpanel_first_received_event_at"
  task :backfill_mixpanel_first_received_event_at => :environment do
    Bot.where(first_received_event_at: nil).find_each do |bot|
      if bot.first_received_event_at.blank?
        first_event = bot.events.order("id").first
        bot.update_attribute(:first_received_event_at, first_event.created_at)
        bot.collaborators.each do |user|
          SetMixpanelPropertyJob.perform_async(user.id, "received_first_event", true)
          puts "Updated #{user.id} #{user.email} received_first_event=true on Mixpanel"
        end
      end
    end
  end
end

