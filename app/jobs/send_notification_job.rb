class SendNotificationJob < Job
  def perform(notification_id)
    notification = Notification.find(notification_id)
    NotificationService.new(notification).send_now
  end
end
