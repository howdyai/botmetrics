class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :find_instances
  before_action :init_detail_view!
  layout 'app'

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
    @events = Event.where(event_type: 'bot_disabled',
                          bot_instance_id: @instances.select(:id),
                          created_at: @start.utc..@end.utc)

    @tableized = @instances.with_disabled_bots(@events.select(:bot_instance_id)).page(params[:page])

    @events = GetResourcesCountByUnit.new(
                @group_by,
                @events,
                user_time_zone: current_user.timezone
              ).call

    TrackMixpanelEventJob.perform_async('Viewed Disabled Bots Dashboard Page', current_user.id)
  end

  def users
    @users = BotUser.where(bot_instance_id: @instances.select(:id)).joins(:bot_instance).
                     where("bot_instances.created_at" => @start.utc..@end.utc)

    @tableized = @users.order("bot_instances.created_at DESC").page(params[:page])

    @users = GetResourcesCountByUnit.new(
               @group_by,
               @users,
               start_time: @start,
               end_time: @end,
               user_time_zone: current_user.timezone
             ).call

    TrackMixpanelEventJob.perform_async('Viewed New Users Dashboard Page', current_user.id)
  end

  def all_messages
    @messages = Event.where(bot_instance_id: @instances.select(:id),
                            event_type: 'message',
                            is_from_bot: false,
                            created_at: @start.utc..@end.utc)

    @tableized = @instances.with_all_messages(@messages.select(:bot_instance_id)).page(params[:page])

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed All Messages Dashboard Page', current_user.id)
  end

  def messages_to_bot
    @messages = Event.where(bot_instance_id: @instances.select(:id),
                            event_type: 'message',
                            is_for_bot: true,
                            created_at: @start.utc..@end.utc)

    @tableized = @instances.with_messages_to_bot(@messages.select(:bot_instance_id)).page(params[:page])

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed Messages To Bot Dashboard Page', current_user.id)
  end

  def messages_from_bot
    @messages = Event.where(bot_instance_id: @instances.select(:id),
                            event_type: 'message',
                            is_from_bot: true,
                            created_at: @start.utc..@end.utc)

    @tableized = @instances.with_messages_from_bot(@messages.select(:bot_instance_id)).page(params[:page])

    @messages = GetResourcesCountByUnit.new(
                  @group_by,
                  @messages,
                  user_time_zone: current_user.timezone
                ).call

    TrackMixpanelEventJob.perform_async('Viewed Messages From Bot Dashboard Page', current_user.id)
  end

  protected
  def find_instances
    if (@instances = @bot.instances.pending).count == 0
      return redirect_to(new_bot_instance_path(@bot))
    end
  end

  def init_detail_view!
    @group_by = params[:group_by].presence || 'day'
    @start, @end = GetStartEnd.new(params[:start], params[:end], current_user.timezone).call
  end

  def find_bot
    @bot = current_user.bots.find_by(uid: params[:bot_id])
    raise ActiveRecord::NotFound if @bot.blank?
  end
end
