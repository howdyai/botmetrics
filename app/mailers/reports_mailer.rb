class ReportsMailer < ApplicationMailer
  def daily_summary(user_id)
    @user = User.find(user_id)

    if monday_in_time_zone?(@user.timezone)
      @weekly_dashboarders = {}
      @user.bots.each do |bot|
        dashboarder = Dashboarder.new(bot.instances.legit, 'this-week', @user.timezone, false)
        dashboarder.init!

        @weekly_dashboarders[bot.name] = dashboarder
      end
    end

    @daily_dashboarders = {}
    @user.bots.each do |bot|
      dashboarder = Dashboarder.new(bot.instances.legit, 'today', @user.timezone, false)
      dashboarder.init!

      @daily_dashboarders[bot.name] = dashboarder
    end

    mail(
      to: @user.email,
      subject: "Your botmetrics Daily Summary for #{yesterday_in_words(@user)}"
    )
  end

  private

    def monday_in_time_zone?(time_zone)
      Time.current.in_time_zone(time_zone).monday?
    end

    def yesterday_in_words(user)
      (Time.current.in_time_zone(user.timezone) - 1.day).strftime('%b %d, %Y')
    end
end
