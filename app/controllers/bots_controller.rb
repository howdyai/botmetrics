class BotsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot, except: [:new, :create, :index]

  layout 'app'

  def new
    @bot = current_user.bots.build
    TrackMixpanelEventJob.perform_async('Viewed New Bot Page', current_user.id)
  end

  def index
    redirect_to bot_path(current_user.bots.first)
  end

  def create
    @bot = Bot.new(bot_params)
    @bot.provider = 'slack'

    if @bot.save
      bc = current_user.bot_collaborators.create(bot: @bot, collaborator_type: 'owner')
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
      webhook_url_changed = @bot.webhook_url != old_webhook_url

      TrackMixpanelEventJob.perform_async('Updated Bot', current_user.id)
      WebhookValidateJob.perform_async(@bot.id) if webhook_url_changed

      respond_to do |format|
        format.html do
          if webhook_url_changed
            redirect_to bot_verifying_webhook_path(@bot)
          else
            redirect_to bot_path(@bot)
          end
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def show
    @group_by = case params[:group_by]
                when '' then 'today'
                when nil then 'today'
                else params[:group_by]
                end

    if (@instances = @bot.instances.where("state <> ?", 'pending')).count == 0
      redirect_to(new_bot_instance_path(@bot)) && return
    end

    @show_trends = (@group_by != 'all-time')
    @dashboarder = Dashboarder.new(@instances, @group_by, current_user.timezone)
    @dashboarder.init!
    TrackMixpanelEventJob.perform_async('Viewed Bot Dashboard Page', current_user.id)
  end

  def verifying_webhook
  end

  protected

  def bot_params
    params.require(:bot).permit(:name, :webhook_url)
  end
end
