class EnqueueNotificationJob < Job
  def perform(notification_id)
    notification = Notification.find(notification_id)
    NotificationService.new(notification).enqueue_messages
  end
end
