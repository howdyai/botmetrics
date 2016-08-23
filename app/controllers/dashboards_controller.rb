class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :init_detail_view!
  layout 'app'

  def new
    @dashboard = @bot.dashboards.new
  end

  def create
    @dashboard = @bot.dashboards.create(dashboard_params.merge!(user: current_user,
                                                                dashboard_type: 'custom',
                                                                provider: @bot.provider,
                                                                enabled: true))

    if @dashboard.persisted?
      redirect_to bot_dashboards_path
    else
      render :new
    end
  end

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

  def dashboard_params
    params.require(:dashboard).permit(:name, :regex, :provider)
  end
end
