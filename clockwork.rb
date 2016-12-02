require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  every(5.minutes, 'RolledupEventQueue.flush') do
    sleep(rand(0.1))
    RolledupEventQueue.flush!
  end

  every(2.minutes, 'Messages.Send') do
    SendScheduledMessageJob.perform_async
  end

  if Rails.env.production? && Setting.hostname.present?
    every(5.minutes, 'DailyReport.Send') do
      SendDailyReportsJob.perform_async
    end
  end

  every(5.minutes, 'Notification.recurring_send') do
    SendRecurringNotificationsJob.perform_async
  end
end
