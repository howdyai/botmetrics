class SendScheduledMessageJob < Job
  def perform
    ScheduledMessageService.new.send_now
  end
end
