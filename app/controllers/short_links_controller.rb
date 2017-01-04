class ShortLinksController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :find_bot, only: [:create]

  def create
    if params[:user_id].blank?
      render json: { message: "user_id is missing" }, status: 400
      return
    end

    if params[:url].blank?
      render json: { message: "url is missing" }, status: 400
      return
    end

    if @bot.provider == 'slack'
      if params[:team_id].blank?
        render json: { message: "team_id is missing" }, status: 400
        return
      end

      bot_instance = @bot.instances.find_by(uid: params[:team_id])
    else
      bot_instance = @bot.instances.first
    end

    raise ActiveRecord::RecordNotFound if bot_instance.blank?

    bot_user = bot_instance.users.find_by(uid: params[:user_id])
    raise ActiveRecord::RecordNotFound if bot_user.blank?

    short_link = bot_instance.short_links.new do |sl|
      sl.url = params[:url]
      sl.bot_user = bot_user
    end

    if short_link.save
      bot_instance.events.create!(event_type: 'followed-link', user: bot_user, event_attributes: { url: short_link.url, slug: short_link.slug }, provider: @bot.provider)
      render json: { url: short_link_url(short_link, host: ENV['SHORTLINK_HOST'] || ENV['RAILS_HOST'], protocol: 'https') }
    else
      render json: { message: short_link.full_messages }, status: 404
    end
  end

  def show
    sl = ShortLink.find_by(slug: params[:id])
    raise ActiveRecord::RecordNotFound if sl.blank?
    redirect_to sl.url
  end
end
