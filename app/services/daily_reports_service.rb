class DailyReportsService
  def send_now
    User.local_time_is_after(9).find_each do |user|
      FeatureToggle.active?(:daily_reports, user) do
        next unless user.subscribed?
        next unless user.can_send_daily_summary?

        ReportsMailer.daily_summary(user.id).deliver_later
      end
    end
  end
end
