class KikEventsCollectorJob < Job
  def perform(bot_id, events_json)
    events = JSON.parse(events_json)
    kik_events_service = KikEventsService.new(bot_id: bot_id, events: events)
    kik_events_service.create_events!
  end
end
