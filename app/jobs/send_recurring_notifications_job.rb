class SendRecurringNotificationsJob < Job
  def perform
    Notification.where(recurring: true).order(:id).each do |n|
      NotificationService.new(n).enqueue_messages
    end
  end
end
