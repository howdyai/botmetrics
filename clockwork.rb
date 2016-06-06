require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  every(30.minutes, 'Messages.Send', at: ['**:00', '**:30']) do
    SendScheduledMessageJob.perform_async
  end

  every(5.minutes, 'DailyReport.Send') do
    SendDailyReportsJob.perform_async
  end
end
