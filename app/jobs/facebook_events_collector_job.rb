class FacebookEventsCollectorJob < Job
  def perform(bot_id, event_json)
    facebook_events_service = FacebookEventsService.new(bot_id: bot_id, raw_data: event_json)
    facebook_events_service.create_event
  end
end
