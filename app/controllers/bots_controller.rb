class BotsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot, except: [:new, :create, :index]

  layout 'app'

  def new
    @bot = current_user.bots.build
    TrackMixpanelEventJob.perform_async('Viewed New Bot Page', current_user.id)

    render :new, layout: 'devise'
  end

  def index
    if(bot = current_user.bots.first).present?
      redirect_to bot_path(current_user.bots.first)
    else
      flash[:info] = "You need to create a bot first!"
      redirect_to new_bot_path
    end
  end

  def create
    @bot = Bot.new(bot_params)

    if @bot.save
      bc = current_user.bot_collaborators.create(bot: @bot, collaborator_type: 'owner', confirmed_at: Time.now)
      if bc.persisted?
        redirect_to bot_path(@bot)
        TrackMixpanelEventJob.perform_async('Created Bot', current_user.id)
      else
        @bot.destroy
        @bot.errors.base.add 'unexpected error while creating your bot'
        render :new
      end
    else
      render :new
    end
  end

  def edit
    TrackMixpanelEventJob.perform_async('Viewed Edit Bot Page', current_user.id)
  end

  def update
    old_webhook_url = @bot.webhook_url

    if @bot.update(bot_params)
      if @bot.webhook_url.present? && @bot.webhook_url != old_webhook_url
        redirect_to bot_verifying_webhook_path(@bot)
      else
        redirect_to bot_path(@bot)
      end

      TrackMixpanelEventJob.perform_async('Updated Bot', current_user.id)
    else
      render :edit
    end
  end

  def show
    session[:bot_id] = @bot.uid
    @group_by = params[:group_by].presence || 'today'

    if (@instances = @bot.instances.legit).count == 0
      redirect_to(new_bot_instance_path(@bot)) && return
    end

    @show_trends = (@group_by != 'all-time')
    @dashboarder = Dashboarder.new(@instances, @group_by, current_user.timezone)
    @dashboarder.init!
    TrackMixpanelEventJob.perform_async('Viewed Bot Dashboard Page', current_user.id)
  end

  def verifying_webhook
    ValidateWebhookAndUpdatesJob.perform_in(0.5.seconds, @bot.id)
    TrackMixpanelEventJob.perform_async('Viewed Verifying Webhook Page', current_user.id)
  end

  def webhook_events
    @tableized = @bot.webhook_events.order("id DESC").page(params[:page])
  end

  protected

  def bot_params
    params.require(:bot).permit(:name, :webhook_url, :provider)
  end
end
