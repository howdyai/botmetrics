class UsersController < ApplicationController
  before_action :authenticate_user!
  layout 'app'

  def show
    @user = current_user
    @bot  = params[:bot_id].present? ? @user.bots.find_by(uid: params[:bot_id]) : @user.bots.first
  end

  def update
    @user = current_user

    if @user.update(model_params)
      redirect_to @user, notice: 'Successfully updated your profile.'
    else
      flash.now[:error] = 'Something went wrong, and we were unable to update your profile. Please try again later.'
      render :show
    end
  end

  def regenerate_api_key
    @user = current_user
    @user.set_api_key!
    @user.save

    flash[:info] = "Regenerated your API Key!"

    redirect_to user_path(@user)
  end

  private
  def model_params
    params.require(:user).permit(:created_bot_instance, :disabled_bot_instance, :daily_reports)
  end
end
