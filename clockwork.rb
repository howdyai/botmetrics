require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  every(2.minutes, 'Messages.Send') do
    SendScheduledMessageJob.perform_async
  end

  every(5.minutes, 'DailyReport.Send') do
    SendDailyReportsJob.perform_async
  end
end
