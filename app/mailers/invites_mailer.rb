class InvitesMailer < ApplicationMailer
  def invite_to_collaborate(invited_user_id, inviting_user_id, bot_id)
    @invited_user = User.find(invited_user_id)
    @inviting_user = User.find(inviting_user_id)
    @bot = @invited_user.bots.find(bot_id)

    mail(
      to: @invited_user.email,
      subject: "#{@inviting_user.full_name} has invited you to view metrics of #{@bot.name} on Botmetrics"
    )
  end
end
