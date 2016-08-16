class AddNewKikConstraintsOnEvents < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX events_id_kik ON events((event_attributes->'id')) WHERE events.provider = 'kik' AND events.event_type = 'message'"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_id
                   CHECK (
                           (
                             (event_attributes->>'id') IS NOT NULL
                             AND length(event_attributes->>'id') > 0
                             AND provider = 'kik'
                             AND event_type = 'message'
                           )
                           OR
                             provider IN ('facebook', 'slack')
                         )"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_chat_id
                  CHECK (
                          (
                            (event_attributes->>'chat_id') IS NOT NULL
                            AND length(event_attributes->>'chat_id') > 0
                            AND provider = 'kik'
                            AND event_type = 'message'
                          )
                          OR
                            provider IN ('facebook', 'slack')
                        )"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_sub_type
                   CHECK (
                           (
                             (event_attributes->>'sub_type') IS NOT NULL
                             AND length(event_attributes->>'sub_type') > 0
                             AND (event_attributes->>'sub_type') IN ('text', 'link', 'picture', 'video', 'start-chatting', 'scan-data', 'sticker', 'is-typing', 'friend-picker')
                             AND provider = 'kik'
                             AND event_type = 'message'
                           )
                           OR
                             provider IN ('facebook', 'slack')
                         )"
  end

  def down
    execute "DROP INDEX events_id_kik"
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_id"
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_chat_id"
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_sub_type"
  end
end
