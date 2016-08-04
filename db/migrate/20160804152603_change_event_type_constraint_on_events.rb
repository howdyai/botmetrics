class ChangeEventTypeConstraintOnEvents < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (event_type = 'user_added'
                      OR event_type = 'bot_disabled'
                      OR event_type = 'added_to_channel'
                      OR ((event_type = 'message'
                      OR event_type = 'message_reaction'
                      OR event_type = 'messaging_postbacks'
                      OR event_type = 'messaging_optins'
                      OR event_type = 'account_linking'
                      OR event_type = 'message_deliveries'
                      OR event_type = 'message_reads'
                      OR event_type = 'message_echoes')
                      AND bot_user_id IS NOT NULL))"

  end

  def down
    execute "ALTER TABLE events DROP CONSTRAINT valid_event_type_on_events"
  end
end
