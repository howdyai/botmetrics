class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted?
        resource.set_api_key!  if resource.api_key.blank?
        resource.signed_up_at = Time.now if resource.signed_up_at.blank?
        resource.save
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
