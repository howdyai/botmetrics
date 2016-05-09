class UsersController < ApplicationController
  before_filter :authenticate_user!
  layout 'app'

  def show
    @user = current_user
    @bot = @user.bots.first

    TrackMixpanelEventJob.perform_async('Viewed User Profile Page', current_user.id)
  end

  def regenerate_api_key
    @user = current_user
    @user.set_api_key!
    @user.save

    flash[:info] = "Regenerated your API Key!"
    TrackMixpanelEventJob.perform_async('Regenerated API Key', current_user.id)

    redirect_to user_path(@user)
  end
end
