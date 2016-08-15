class StaticController < ApplicationController
  layout 'bare'

  def index
    if current_user.present?
      if(bot = current_user.bots.first).present?
        redirect_to bot_path(current_user.bots.first)
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
