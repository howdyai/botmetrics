class FacebookEventsJob < Job
  def perform(bot_id, raw_data)
    facebook_events_service = FacebookEventsService.new(bot_id: bot_id, raw_data: raw_data)
    facebook_events_service.create_event
  end
end
