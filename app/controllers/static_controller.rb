class StaticController < ApplicationController
  layout 'bare'

  def index
    if current_user.present?
      if current_user.bots.count > 0
        bot = session[:bot_id] ? Bot.find_by(uid: session[:bot_id]) : current_user.bots.enabled.first

        redirect_to bot_path(bot)
      else
        redirect_to new_bot_path
      end
    else
      render :index
    end
  end

  def privacy
  end

  def letsencrypt
    render text: Settings.letsencrypt_challenge
  end
end
