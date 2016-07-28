class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted?
        mixpanel_properties = @mixpanel_attributes.dup
        mixpanel_properties.delete('distinct_id')

        resource.mixpanel_properties = mixpanel_properties
        resource.set_api_key!  if resource.api_key.blank?
        resource.signed_up_at = Time.now if resource.signed_up_at.blank?
        resource.save

        IdentifyMixpanelUserJob.perform_async(resource.id, @mixpanel_attributes)
        TrackMixpanelEventJob.perform_async('User Signed Up', resource.id, mixpanel_properties)
        NotifyAdminOnSlackJob.perform_async(resource.id, title: 'User Signed Up')
      end
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
    new_bot_path
  end
end
