class AlertsMailer < ApplicationMailer
  def created_bot_instance(bot_instance_id, user_id)
    @bot_instance = BotInstance.find(bot_instance_id)
    @user         = User.find(user_id)

    mail(
      to:      @bot_instance.owners.map(&:email),
      subject: 'A New Bot Instance Created!'
    )
  end
end
