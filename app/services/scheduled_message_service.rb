class ScheduledMessageService
  def send_now
    nearest_time = NearestTime.round(Time.current)

    Message.scheduled.find_each do |message|
      if message.can_send_now?(nearest_time)
        Rails.logger.info "[SendScheduledMessageJob] Sending Message for ID #{message.id}"

        SendMessageJob.perform_async(message.id)
      end
    end
  end
end
