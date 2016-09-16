class BotInstancesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def new
    @instance = @bot.instances.build
  end

  def create
    @instance = @bot.build_instance(instance_params)
    @instance.provider = @bot.provider
    if (created_at = params[:instance][:created_at])
      @instance.created_at = Time.at(created_at.to_i)
    end

    if @instance.save
      SetupBotJob.perform_async(@instance.id, current_user.id)

      respond_to do |format|
        format.html { redirect_to setting_up_bot_instance_path(@bot, @instance) }
        format.json { render json: { id: @instance.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: @instance.errors.full_messages }, status: :bad_request }
      end
    end
  end

  def edit
    if @bot.provider != 'facebook'
      redirect_to(bot_path(@bot)) && return
    end

    @instance = @bot.instances.find(params[:id])
  end

  def update
    if @bot.provider != 'facebook'
      redirect_to(bot_path(@bot)) && return
    end

    @instance = @bot.instances.find(params[:id])

    if @instance.update_attributes(update_instance_params)
      SetupBotJob.perform_async(@instance.id, current_user.id)

      respond_to do |format|
        format.html { redirect_to setting_up_bot_instance_path(@bot, @instance) }
      end
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def show
    @instance = @bot.instances.find(params[:id])
    render json: { state: @instance.state }
  end

  def setting_up
    @instance = @bot.instances.find(params[:id])
  end

  protected
  def instance_params
    params.require(:instance).permit(:token, :uid, :created_at)
  end

  def update_instance_params
    params.require(:instance).permit(:token)
  end
end
