class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_action :find_bot

  def create
    facebook_events_job
    render nothing: true, status: :accepted
  end

private

  def facebook_events_job
    @facebook_events_job ||= FacebookEventsJob.perform_async(params['bot_id'], JSON.parse(params['event']))
  end
end
