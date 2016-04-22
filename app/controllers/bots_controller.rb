class BotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team

  def show
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?

    if @bot.instances.count == 0
      redirect_to(new_team_bot_instance_path(@team, @bot)) && return
    end

  end

  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end
end
