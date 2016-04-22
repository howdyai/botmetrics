class BotInstancesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team
  before_filter :find_bot

  def new
    @instance = @bot.instances.build
  end

  def create
    @instance = @bot.instances.create(instance_params)

    if @instance.persisted?
      redirect_to team_bot_path(@team, @bot)
    else
      render :new
    end
  end

  protected
  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end

  def find_bot
    @bot = @team.bots.find_by(uid: params[:bot_id])
    raise ActiveRecord::RecordNotFound if @bot.blank?
  end

  def instance_params
    params.require(:instance).permit(:token, :uid)
  end
end
