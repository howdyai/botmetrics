class InvitationsController < Devise::InvitationsController
  def create
    super do |resource|
      if resource.persisted?
        bot = current_user.bots.find_by(uid: params[:invite][:bot_id])
        BotCollaborator.create!(bot: bot, user: resource, collaborator_type: 'member')
        TrackMixpanelEventJob.perform_async('Invited Collaborator to Bot', current_user.id, bot_id: bot.uid)

        resource.deliver_invitation
      end
    end
  end

  protected
  def invite_resource
    ## skip sending emails on invite
    ## They will be sent after the bot has been added to user
    super do |u|
      u.skip_invitation = true
    end
  end

  def invite_params
    i_params = params.require(:invite).permit(:full_name, :email, :timezone, :timezone_utc_offset, :bot_id)

    tz = Time.find_zone(i_params[:timezone])
    if tz.present?
      i_params[:timezone] = tz.name
      i_params[:timezone_utc_offset] = tz.utc_offset
    else
      i_params[:timezone] = nil
    end

    i_params
  end
end
