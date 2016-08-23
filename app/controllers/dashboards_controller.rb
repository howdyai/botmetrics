class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :init_detail_view!
  layout 'app'

  def index
    @dashboards = @bot.dashboards.where(enabled: true).order("id")
    @group_by = params[:group_by].presence || 'today'
    @show_trends = (@group_by != 'all-time')

    @dashboards.each do |dashboard|
      dashboard.group_by = @group_by
      dashboard.init!
    end

    TrackMixpanelEventJob.perform_async('Viewed Bot Dashboard Page', current_user.id)
  end

  def show
    @dashboard = @bot.dashboards.find_by(uid: params[:id], enabled: true)

    @dashboard.group_by = @group_by
    @dashboard.start_time = @start
    @dashboard.end_time = @end
    @dashboard.page = params[:page]
    @dashboard.should_tableize = true

    @dashboard.init!
    TrackMixpanelEventJob.perform_async("Viewed #{@dashboard.name} Dashboard Page", current_user.id)
  end

  protected
  def init_detail_view!
    @group_by = params[:group_by].presence || 'day'
    @start, @end = GetStartEnd.new(params[:start], params[:end], current_user.timezone).call
  end
end
