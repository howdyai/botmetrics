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
    render text: 'hIbdrX6Kkog-Jf9W94K5nJ6VXNUn8U61s-xKUn6Puss.46T4ETl3cFnTgHvAPLmpVqV3yv-8M6dJGWobu-kh0zw'
  end
end
