class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_action :find_bot

  def create
    case @bot.provider
    when 'facebook'
      FacebookEventsCollectorJob.perform_async(@bot.uid, params[:event])
    end

    render nothing: true, status: :accepted
  end
end
