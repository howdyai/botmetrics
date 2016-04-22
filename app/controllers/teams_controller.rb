class TeamsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @team = current_user.teams.find_by(uid: params[:id])
    if @team.bots.count == 1
      @bot = @team.bots.first
      redirect_to(team_bot_path(@team, @bot)) && return
    end
  end
end
