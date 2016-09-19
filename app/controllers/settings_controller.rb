class SettingsController < ApplicationController
  before_action :authenticate_user!
  layout 'devise'

  def new
    if Setting.count > 0
      redirect_to(bots_path) && return
    end

    @setting = Setting.new
    @setting.hostname = request.protocol + request.host
    unless (request.port == 80 || request.port == 443)
      @setting.hostname = "#{@setting.hostname}:#{request.port}"
    end
  end

  def create
    @setting = Setting.new
    @setting.hostname = params[:setting][:hostname]

    if @setting.save
      redirect_to bots_path
    else
      render :new
    end
  end
end
