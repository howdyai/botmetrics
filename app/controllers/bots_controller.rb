class BotsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot, except: [:new, :create, :index]

  layout 'app'

  def new
    @bot = current_user.bots.build

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
        @bot.create_default_dashboards_with!(current_user)
        redirect_to bot_path(@bot)
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
  end

  def update
    old_webhook_url = @bot.webhook_url

    if @bot.update(bot_params)
      if @bot.webhook_url.present? && @bot.webhook_url != old_webhook_url
        redirect_to bot_verifying_webhook_path(@bot)
      else
        redirect_to bot_path(@bot)
      end
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

    redirect_to bot_dashboards_path(@bot)
  end

  def verifying_webhook
    ValidateWebhookAndUpdatesJob.perform_in(0.5.seconds, @bot.id)
  end

  def webhook_events
    @tableized = @bot.webhook_events.order("id DESC").page(params[:page])
  end

  protected

  def bot_params
    params.require(:bot).permit(:name, :webhook_url, :provider)
  end
end
