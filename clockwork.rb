require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  every(30.minutes, 'Messages.Send', at: ['**:00', '**:30']) do
    SendScheduledMessageJob.perform_async
  end

  every(1.hour, 'DailyReport.Send', at: ['**:00']) do
    SendDailyReportsJob.perform_async
  end
end
