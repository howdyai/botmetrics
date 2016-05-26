class DailyReportsService
  def send_now
    User.find_each do |user|
      FeatureToggle.active?(:daily_reports, user) do
        next unless subscribed?(user)
        next unless is_9am_in_user_timezone?(user)

        Rails.logger.info "[SendDailyReportsJob] Sending Summary Email for ID #{user.id}"

        ReportsMailer.daily_summary(user.id).deliver_later
      end
    end
  end

  private

    def subscribed?(user)
      user.daily_reports == '1'
    end

    def is_9am_in_user_timezone?(user)
      Time.current.in_time_zone(user.timezone).hour == 9
    end
end
