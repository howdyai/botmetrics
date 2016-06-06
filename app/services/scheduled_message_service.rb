class ScheduledMessageService
  def send_now
    Message.scheduled.find_each do |message|
      next unless message.can_send_now?

      SendMessageJob.perform_async(message.id)
    end
  end
end
