class InvitationsController < Devise::InvitationsController
  def create
    existing_user = User.find_by(email: params[:invite][:email])
    bot = current_user.bots.find_by(uid: params[:invite][:bot_id])

    if existing_user.present? && existing_user.signed_up_at.present?
      add_to_bot!(existing_user, bot)
      flash[:info] = "Invitation sent to #{existing_user.email}"
      redirect_to(bot_path(bot.id)) && return
    end

    super do |resource|
      add_to_bot!(resource, bot) if resource.persisted?
    end
  end

  def update
    super do |resource|
      if resource.errors.empty?
        resource.update_attribute(:signed_up_at, Time.now) if resource.signed_up_at.blank?
        resource.bot_collaborators.where(confirmed_at: nil).update_all(confirmed_at: Time.now)
      end
    end
  end

  protected
  def add_to_bot!(invited_user, bot)
    if BotCollaborator.find_by(bot_id: bot.id, user_id: invited_user.id).blank?
      BotCollaborator.create!(bot: bot,
                              user: invited_user,
                              collaborator_type: 'member',
                              confirmed_at: invited_user.signed_up_at.present? ? Time.now : nil)

      TrackMixpanelEventJob.perform_async('Invited Collaborator to Bot', current_user.id, bot_id: bot.uid)

      if invited_user.signed_up_at.blank?
        invited_user.deliver_invitation
      else
        InvitesMailer.invite_to_collaborate(invited_user.id, current_user.id, bot.id).deliver_later
      end
    end
  end

  def invite_resource
    ## skip sending emails on invite
    ## They will be sent after the bot has been added to user
    super { |u| u.skip_invitation = true }
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
