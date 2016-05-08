class BotInstancesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_team
  before_filter :find_bot

  layout 'app'

  def new
    @instance = @bot.instances.build
    TrackMixpanelEventJob.perform_async('Viewed New Bot Instance Page', current_user.id)
  end

  def create
    @instance = @bot.instances.build(instance_params)
    @instance.provider = @bot.provider
    if (created_at = params[:instance][:created_at])
      @instance.created_at = Time.at(created_ts.to_i)
    end

    if @instance.save
      TrackMixpanelEventJob.perform_async('Started Bot Instance Creation', current_user.id)
      SetupBotJob.perform_async(@instance.id, current_user.id)

      respond_to do |format|
        format.html { redirect_to setting_up_team_bot_instance_path(@team, @bot, @instance) }
        format.json { render json: { id: @instance.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: @instance.errors.full_messages }, status: :bad_request }
      end
    end
  end

  def setting_up
    @instance = @bot.instances.find(params[:id])
  end

  protected
  def find_team
    @team = current_user.teams.find_by(uid: params[:team_id])
    raise ActiveRecord::RecordNotFound if @team.blank?
  end

  def find_bot
    @bot = @team.bots.find_by(uid: params[:bot_id])
    raise ActiveRecord::RecordNotFound if @bot.blank?
  end

  def instance_params
    params.require(:instance).permit(:token, :created_at)
  end
end
