class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      bot = Bot.create!(name: 'My First Bot', provider: 'slack')
      resource.bot_collaborators.create!(bot: bot, collaborator_type: 'owner')

      mixpanel_properties = @mixpanel_attributes.dup
      mixpanel_properties.delete('distinct_id')

      resource.mixpanel_properties = mixpanel_properties

      if resource.api_key.blank?
        resource.set_api_key!
      end

      resource.save

      IdentifyMixpanelUserJob.perform_async(resource.id, @mixpanel_attributes)
      TrackMixpanelEventJob.perform_async('User Signed Up', resource.id, mixpanel_properties)
    end
  end

  protected
  def sign_up_params
    su_params = params.require(:user).permit(:full_name, :email, :password, :timezone, :timezone_utc_offset)

    tz = Time.find_zone(su_params[:timezone])
    if tz.present?
      su_params[:timezone] = tz.name
      su_params[:timezone_utc_offset] = tz.utc_offset
    else
      su_params[:timezone] = nil
    end

    su_params
  end

  def after_sign_up_path_for(resource)
    bot_path(resource.bots.first)
  end
end
