class BotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team

  layout 'app'

  def show
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?

    if (@instances = @bot.instances.where("state <> ?", 'pending')).count == 0
      redirect_to(new_team_bot_instance_path(@team, @bot)) && return
    end

    instance_ids = @instances.select(:id)

    @enabled = @instances.enabled
    @disabled = @instances.disabled
    @members = BotUser.where("bot_instance_id IN (?)", instance_ids)
    @messages = Event.where("bot_instance_id IN (?)", instance_ids)

    @messages_to_bot = @messages.where(is_for_bot: true)
    @messages_from_bot = @messages.where(is_from_bot: true)
  end

  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end
end
