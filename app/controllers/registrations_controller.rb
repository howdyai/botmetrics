class RegistrationsController < Devise::RegistrationsController
  def new
    if redirect_if_admin_account_setup
      return
    end

    super do |resource|
      resource.subscribe_to_updates_and_security_patches = true
    end
  end

  def create
    if redirect_if_admin_account_setup
      return
    end

    subscribe_user = params[:user][:subscribe_to_updates_and_security_patches] == '1'

    super do |resource|
      if resource.persisted?
        resource.set_api_key!  if resource.api_key.blank?
        resource.signed_up_at = Time.now if resource.signed_up_at.blank?
        resource.site_admin = true
        resource.save

        if subscribe_user
          SubscribeUserToUpdatesJob.perform_async(resource.id)
        end
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
    new_setting_path
  end

  def redirect_if_admin_account_setup
    if User.count > 0
      flash[:error] = "An admin account has already been created for this install of Botmetrics"
      redirect_to(root_path)
      return true
    end

    return false
  end
end
