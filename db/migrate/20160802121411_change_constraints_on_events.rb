class ChangeConstraintsOnEvents < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_channel"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_timestamp"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_reaction"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_channel
                   CHECK (((event_attributes->>'channel') IS NOT NULL
                       AND length(event_attributes->>'channel') > 0
                       AND provider = 'slack'
                       AND (event_type = 'message' OR event_type = 'message_reaction'))
                        OR (provider = 'slack'
                       AND (event_type <> 'message' AND event_type <> 'message_reaction')
                       AND event_attributes IS NOT NULL)
                        OR provider = 'facebook')"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_timestamp
                   CHECK (((event_attributes->>'timestamp') IS NOT NULL
                       AND length(event_attributes->>'timestamp') > 0
                       AND provider = 'slack'
                       AND (event_type = 'message' OR event_type = 'message_reaction'))
                        OR (provider = 'slack'
                       AND (event_type <> 'message' AND event_type <> 'message_reaction')
                       AND event_attributes IS NOT NULL)
                        OR provider = 'facebook')"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_reaction
                   CHECK (((event_attributes->>'reaction') IS NOT NULL
                       AND length(event_attributes->>'reaction') > 0
                       AND provider = 'slack'
                       AND event_type = 'message_reaction')
                        OR (provider = 'slack'
                       AND event_type <> 'message_reaction'
                       AND event_attributes IS NOT NULL)
                        OR provider = 'facebook')"
  end

  def down
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_channel"
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_timestamp"
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_reaction"
  end
end
