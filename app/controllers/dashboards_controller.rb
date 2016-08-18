class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :find_instances
  before_action :init_detail_view!
  layout 'app'

  def index
    @dashboards = @bot.dashboards.where(enabled: true).order("id")
    @group_by = params[:group_by].presence || 'today'
    @show_trends = (@group_by != 'all-time')

    @dashboards.each do |dashboard|
      dashboard.instances = @instances
      dashboard.group_by = @group_by
      dashboard.init!
    end
  end

  def show
    @dashboard = @bot.dashboards.find_by(uid: params[:id], enabled: true)

    @dashboard.instances = @instances
    @dashboard.group_by = @group_by
    @dashboard.start_time = @start
    @dashboard.end_time = @end
    @dashboard.page = params[:page]
    @dashboard.should_tableize = true

    @dashboard.init!
  end

  def new_bots
    @tableized = @instances.with_new_bots(@start.utc, @end.utc).page(params[:page])

    @new_bots = GetResourcesCountByUnit.new(
                  @group_by,
                  @instances,
                  start_time: @start,
                  end_time: @end,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed New Bots Dashboard Page', current_user.id)
  end

  def disabled_bots
    @events = Event.with_disabled_bots(@instances, @start.utc, @end.utc)

    @tableized = @instances.with_disabled_bots(@events.select(:bot_instance_id)).page(params[:page])

    @events = GetResourcesCountByUnit.new(
                @group_by,
                @events,
                user_time_zone: current_user.timezone
              ).call

    TrackMixpanelEventJob.perform_async('Viewed Disabled Bots Dashboard Page', current_user.id)
  end

  def users
    @users = BotUser.with_bot_instances(@instances, @bot, @start.utc, @end.utc)
    @tableized = @users.order("bot_users.created_at DESC").page(params[:page])

    @users = GetResourcesCountByUnit.new(
               @group_by,
               @users,
               group_table: @bot.provider == 'slack' ? 'bot_instances' : 'bot_users',
               user_time_zone: current_user.timezone
             ).call

    TrackMixpanelEventJob.perform_async('Viewed New Users Dashboard Page', current_user.id)
  end

  def all_messages
    @messages = Event.with_all_messages(@instances, @start.utc, @end.utc)

    @tableized = @instances.with_all_messages(@messages.select(:bot_instance_id)).page(params[:page])

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed All Messages Dashboard Page', current_user.id)
  end

  def messages_to_bot
    @messages = Event.with_messages_to_bot(@instances, @start.utc, @end.utc)

    @tableized = case @bot.provider
                 when 'slack'
                   @instances.with_messages_to_bot(@messages.select(:bot_instance_id)).page(params[:page])
                 when 'facebook', 'kik'
                   BotUser.with_messages_to_bot(@messages.select(:bot_instance_id)).page(params[:page])
                 end

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed Messages To Bot Dashboard Page', current_user.id)
  end

  def messages_from_bot
    @messages = Event.with_messages_from_bot(@instances, @start.utc, @end.utc)

    @tableized = case @bot.provider
                 when 'slack'
                   @instances.with_messages_from_bot(@messages.select(:bot_instance_id)).page(params[:page])
                 when 'facebook', 'kik'
                   BotUser.with_messages_from_bot(@messages.select(:bot_instance_id)).page(params[:page])
                 end

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed Messages From Bot Dashboard Page', current_user.id)
  end

  protected

  def find_instances
    if (@instances = @bot.instances.legit).count == 0
      return redirect_to(new_bot_instance_path(@bot))
    end
  end

  def init_detail_view!
    @group_by = params[:group_by].presence || 'day'
    @start, @end = GetStartEnd.new(params[:start], params[:end], current_user.timezone).call
  end
end
