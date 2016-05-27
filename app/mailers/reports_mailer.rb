class ReportsMailer < ApplicationMailer
  def daily_summary(user_id)
    @user = User.find(user_id)


    if monday_in_time_zone?(@user.timezone)
      @weekly_dashboarders = {}
      @user.bots.each do |bot|
        dashboarder = Dashboarder.new(bot.instances, 'this-week', @user.timezone, false)
        dashboarder.init!

        @weekly_dashboarders[bot.name] = dashboarder
      end
    end

    @daily_dashboarders = {}
    @user.bots.each do |bot|
      dashboarder = Dashboarder.new(bot.instances, 'today', @user.timezone, false)
      dashboarder.init!

      @daily_dashboarders[bot.name] = dashboarder
    end

    mail(
      to: @user.email,
      subject: "Your botmetrics Daily Summary for #{Date.yesterday.strftime('%d %b, %Y')}"
    )
  end

  private

    def monday_in_time_zone?(time_zone)
      Time.current.in_time_zone(time_zone).monday?
    end
end
