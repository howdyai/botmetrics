class AlertsMailer < ApplicationMailer
  helper :mail

  def created_bot_instance(bot_instance_id, user_id)
    @bot_instance = BotInstance.find(bot_instance_id)
    @user         = User.find(user_id)

    to = recipient_emails(@bot_instance.collaborators, :created_bot_instance)
    return if to.blank?

    mail(
      to: to,
      subject: "A New Team Signed Up for #{@bot_instance.bot.name}"
    )
  end

  def disabled_bot_instance(bot_instance_id)
    @bot_instance = BotInstance.find(bot_instance_id)

    to = recipient_emails(@bot_instance.collaborators, :disabled_bot_instance)
    return if to.blank?
    @user = @bot_instance.collaborators.first

    mail(
      to: to,
      subject: "A Team Disabled #{@bot_instance.bot.name}"
    )
  end

  private
  def recipient_emails(users, setting)
    users.subscribed_to(setting).pluck(:email)
  end
end
