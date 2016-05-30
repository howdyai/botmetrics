class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @tableized = BotUser.where(bot_instance_id: @bot.instances.ids).page(params[:page])
  end
end
