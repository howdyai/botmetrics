class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_action :find_bot

  def create
    render nothing: true, status: :accepted
  end

private

  def events_service
    events_service ||= EventsService.new
  end
end
