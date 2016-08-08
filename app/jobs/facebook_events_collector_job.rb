class FacebookEventsCollectorJob < Job
  def perform(bot_id, events_json)
    events = JSON.parse(events_json)
    fb_events_service = FacebookEventsService.new(bot_id: bot_id, events: events)
    fb_events_service.create_events!
  end
end
