class StaticController < ApplicationController
  layout 'bare'

  def index
    if current_user.present?
      redirect_to(bot_path(current_user.bots.first)) && return
    end
  end

  def privacy
  end

  def letsencrypt
    render text: Settings.letsencrypt_challenge
  end
end
