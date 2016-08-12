class DailyReportsService
  def send_now
    User.local_time_is_after(9).find_each do |user|
      next unless user.subscribed_to_daily_summary?
      next unless user.can_send_daily_summary?

      Rails.logger.info "[ReportsMailer] Sending Daily Report to #{user.id} #{user.email} at #{Time.now}"
      ReportsMailer.daily_summary(user.id).deliver_later
    end
  end
end
