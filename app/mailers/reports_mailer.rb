class ReportsMailer < ApplicationMailer
  def daily_summary(user_id)
    @user = User.find(user_id)

    @dashboarders = {}
    @user.bots.each do |bot|
      dashboarder = Dashboarder.new(bot.instances, 'today', @user.timezone, false)
      dashboarder.init!

      @dashboarders[bot.name] = dashboarder
    end

    mail(
      to: @user.email,
      subject: "Your botmetrics Daily Summary for #{Date.yesterday.strftime('%d %b, %Y')}"
    )
  end
end
