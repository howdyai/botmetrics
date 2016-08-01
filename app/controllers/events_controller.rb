class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_action :find_bot

  def create
    render nothing: true, status: :created
  end
end
