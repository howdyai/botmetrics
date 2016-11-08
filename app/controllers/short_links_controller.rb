class ShortLinksController < ApplicationController
  before_action :authenticate_user!

  def create
    #if not slack  (Refactor for Slack to test)

    if (params[:bot_id].blank? || params[:bot_user_id].blank?|| params[:url].blank?) 
      render json: { message: "Url or Bot Id is Missing", status: 404 }, :status => 404
      return
    end 

    bot = current_user.bots.find_by(uid: params[:bot_id])

    bot_instance = bot.instances.first
    bot_user = bot_instance.users.find_by(uid: params[:bot_user_id])
    
    @item = bot_instance.short_links.new do |sl|
      sl.url = params[:url]
      sl.bot_user = bot_user
    end

    if @item.save!
      render json: @item.to_json
    else
      render json: { message: "Url or Bot Id is Missing", status: 404 }, :status => 404
    end

  end

  def shortlink_params
    params.permit(:url, :bot_instance_id, :bot_user_id)
  end

  def show
    puts params.inspect
    sl = ShortLink.find_by(slug: params[:id])
    puts sl.inspect
    puts "hi"
    if sl
       redirect_to sl.url
    else 
       render json: { message: "No URL Found", status: 404 }, :status => 404
    end
  end

  def index
    redirect_to root_path
  end

end
