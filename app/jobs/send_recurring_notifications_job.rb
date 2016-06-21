class SendRecurringNotificationsJob < Job
  def perform
    Notification.where(recurring: true).each do |n|
      NotificationService.new(notification).enqueue_messages
    end
  end
end
