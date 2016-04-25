class AddConstraintsToEvents < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_channel CHECK (((event_attributes->>'channel') IS NOT NULL AND length(event_attributes->>'channel') > 0 AND provider = 'slack' AND event_type = 'message') OR (provider = 'slack' AND (event_type <> 'message' AND event_type <> 'message_reaction') AND event_attributes IS NOT NULL))"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_timestamp CHECK (((event_attributes->>'timestamp') IS NOT NULL AND length(event_attributes->>'timestamp') > 0 AND provider = 'slack' AND event_type = 'message') OR (provider = 'slack' AND event_type <> 'message' AND event_type <> 'message_reaction'  AND event_attributes IS NOT NULL))"
  end

  def down
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_channel"
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_timestamp"
  end
end
