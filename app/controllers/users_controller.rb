class UsersController < ApplicationController
  before_filter :authenticate_user!
  layout 'app'

  def show
    @user = current_user
    @team = @user.teams.first
  end

  def regenerate_api_key
    @user = current_user
    @user.set_api_key!
    @user.save

    flash[:info] = "Regenerated your API Key!"
    redirect_to user_path(@user)
  end
end
