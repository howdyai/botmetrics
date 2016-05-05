class BotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team
  before_filter :find_bot, except: [:new, :create]

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
  end

  def update
    if @bot.update_attributes(bot_params)
      redirect_to team_bot_path(@team, @bot)
    else
      render :edit
    end
  end

  def show
    @group_by = case params[:group_by]
                when '' then 'today'
                when nil then 'today'
                else params[:group_by]
                end

    if (@instances = @bot.instances.where("state <> ?", 'pending')).count == 0
      redirect_to(new_team_bot_instance_path(@team, @bot)) && return
    end

    @show_trends = (@group_by != 'all-time')
    @dashboarder = Dashboarder.new(@instances, @group_by, current_user.timezone)
    @dashboarder.init!
  end

  def new_bots
    init_detail_view!

    @new_bots = case @group_by
                when 'day'
                  @instances.group_by_day(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'week'
                  @instances.group_by_week(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'month'
                  @instances.group_by_month(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                end
  end

  def disabled_bots
    init_detail_view!
    @events = Event.where(event_type: 'bot_disabled', bot_instance_id: @instances.select(:id))
    @events = case @group_by
                when 'day'
                  @events.group_by_day(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'week'
                  @events.group_by_week(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'month'
                  @events.group_by_month(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                end
  end

  def users
    init_detail_view!
    @users = BotUser.where(bot_instance_id: @instances.select(:id))
    @users = case @group_by
                when 'day'
                  @users.group_by_day(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'week'
                  @users.group_by_week(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                when 'month'
                  @users.group_by_month(:created_at, range: @start..@end, time_zone: current_user.timezone).count
                end
  end

  protected
  def init_detail_view!
    if (@instances = @bot.instances.where("state <> ?", 'pending')).count == 0
      redirect_to(new_team_bot_instance_path(@team, @bot)) && return
    end

    @group_by = case params[:group_by]
                when '' then 'day'
                when nil then 'day'
                else params[:group_by]
                end

    @start = params[:start].to_s.in_time_zone(current_user.timezone)
    @start = (Time.now - 6.days).in_time_zone(current_user.timezone) if @start.blank?
    @end  = params[:end].to_s.in_time_zone(current_user.timezone)
    @end = @start + 6.days if @end.blank?

    @start = @start.beginning_of_day
    @end = @end.end_of_day
  end

  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end

  def find_bot
    @bot = @team.bots.find_by(uid: params[:id])
    raise ActiveRecord::NotFound if @bot.blank?
  end

  def bot_params
    params.require(:bot).permit(:name)
  end
end
