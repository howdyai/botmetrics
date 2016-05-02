class BotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team

  layout 'app'

  def new
    @bot = @team.bots.build
  end

  def create
    @bot = @team.bots.build(bot_params)
    @bot.provider = 'slack'

    if @bot.save
      redirect_to team_bot_path(@team, @bot)
    else
      render :new
    end
  end

  def edit
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?
  end

  def update
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?

    if @bot.update_attributes(bot_params)
      redirect_to team_bot_path(@team, @bot)
    else
      render :edit
    end
  end

  def show
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?

    @group_by = case params[:group_by]
                when '' then 'today'
                when nil then 'today'
                else params[:group_by]
                end

    @start_time = case @group_by
                  when 'today' then Time.now.in_time_zone(Time.find_zone(current_user.timezone)).beginning_of_day.utc
                  when 'this-week' then Time.now.in_time_zone(Time.find_zone(current_user.timezone)).beginning_of_week.utc
                  when 'this-month' then Time.now.in_time_zone(Time.find_zone(current_user.timezone)).beginning_of_month.utc
                  when 'all-time' then Time.at(0)
                  end

    if (@instances = @bot.instances.where("state <> ?", 'pending')).count == 0
      redirect_to(new_team_bot_instance_path(@team, @bot)) && return
    end

    instance_ids = @instances.select(:id)

    @all = @instances.where("created_at > ?", @start_time)
    @enabled = @instances.enabled.where("created_at > ?", @start_time)
    @disabled = Event.where("event_type = ? AND created_at > ?", 'bot_disabled', @start_time)
    @members = BotUser.where("bot_instance_id IN (?) AND created_at > ?", instance_ids, @start_time)
    @messages = Event.where("bot_instance_id IN (?) AND created_at > ?", instance_ids, @start_time).
                      where(event_type: 'message', is_from_bot: false)

    @messages_to_bot = @messages.where(is_for_bot: true, event_type: 'message')
    @messages_from_bot = @messages.where(is_from_bot: true, event_type: 'message')
  end

  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end

  protected
  def bot_params
    params.require(:bot).permit(:name)
  end
end
