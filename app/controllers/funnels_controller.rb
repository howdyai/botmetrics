class FunnelsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    if (@funnels = @bot.funnels).count == 0
      redirect_to(new_bot_funnel_path) && return
    end
  end

  def new
    @funnel = @bot.funnels.build(name: "My #{(@bot.funnels.count + 1).ordinalize} Funnel")
    @dashboards = @bot.dashboards.enabled.for_funnels.map { |d| [d.funnel_name, d.uid] }
  end

  def create
    @dashboards = @bot.dashboards.enabled.for_funnels.map { |d| [d.funnel_name, d.uid] }

    @funnel = @bot.funnels.build(name: params[:funnel][:name], creator: current_user)
    update_dashboards_for_funnel!

    if @funnel.save
      redirect_to bot_funnel_path(@bot, @funnel)
    else
      render :new
    end
  end

  def destroy
    @funnel = @bot.funnels.find_by(uid: params[:id])
    raise ActiveRecord::RecordNotFound if @funnel.blank?

    @funnel.destroy
    redirect_to bot_funnels_path
  end

  def update
    @funnel = @bot.funnels.find_by(uid: params[:id])
    raise ActiveRecord::RecordNotFound if @funnel.blank?

    if(name = params[:funnel][:name]).to_s.strip.present?
      @funnel.name = params[:funnel][:name]
    end

    update_dashboards_for_funnel!

    if @funnel.save
      redirect_to bot_funnel_path(@bot, @funnel)
    else
      render :edit
    end
  end

  def edit
    @funnel = @bot.funnels.find_by(uid: params[:id])
    raise ActiveRecord::RecordNotFound if @funnel.blank?

    @dashboards = @bot.dashboards.enabled.for_funnels.map { |d| [d.funnel_name, d.uid] }
  end

  def show
    @funnel = @bot.funnels.find_by(uid: params[:id])
    raise ActiveRecord::RecordNotFound if @funnel.blank?

    @start, @end = GetStartEnd.new(params[:start], params[:end], current_user.timezone).call

    @conversion_data = @funnel.conversion(start_time: @start, end_time: @end)
    @x_axis = @conversion_data.keys
    @y_axis = @conversion_data.values
  end

  protected
  def update_dashboards_for_funnel!
    dash_hash = {}
    @funnel.dashboards = []

    params[:funnel][:dashboards].each do |d_id|
      if d_id == 'abandoned-chat'
        @funnel.dashboards << "dashboard:#{d_id}"
      else
        if (dash = @bot.dashboards.find_by(uid: d_id)).present?
          if !dash_hash.has_key?(dash.uid)
            @funnel.dashboards << "dashboard:#{dash.uid}"
            dash_hash[dash.uid] = dash
          end
        end
      end
    end
  end
end
