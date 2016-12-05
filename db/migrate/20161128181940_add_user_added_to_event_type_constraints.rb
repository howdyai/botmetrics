class AddUserAddedToEventTypeConstraints < ActiveRecord::Migration
  def up
    execute "DELETE FROM events WHERE event_type = 'user_added'"

    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_id"

    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_id
                   CHECK (
                           (
                             (event_attributes->>'id') IS NOT NULL
                             AND length(event_attributes->>'id') > 0
                             AND provider = 'kik'
                           )
                           OR
                             provider IN ('facebook', 'slack', 'kik')
                         )"

    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (
                          (
                            event_type IN ('user-added', 'bot-installed', 'bot_disabled', 'added_to_channel', 'message', 'message_reaction')
                          ) AND provider = 'slack'
                          OR (
                            (
                              event_type IN ('user-added', 'message', 'messaging_postbacks', 'messaging_optins', 'account_linking', 'messaging_referrals', 'message:image-uploaded', 'message:audio-uploaded', 'message:video-uploaded', 'message:file-uploaded', 'message:location-sent')
                            ) AND provider = 'facebook'
                          ) AND bot_user_id IS NOT NULL
                          OR (
                            (
                              event_type IN ('user-added', 'message', 'message:image-uploaded', 'message:video-uploaded', 'message:link-uploaded', 'message:scanned-data', 'message:sticker-uploaded', 'message:friend-picker-chosen', 'message:is-typing', 'message:start-chatting')
                            ) AND provider = 'kik'
                          ) AND bot_user_id IS NOT NULL
                        )"
    execute <<-SQL
  INSERT INTO events (bot_instance_id, event_type, provider, created_at, updated_at)
  SELECT
    bi.id, 'bot-installed', bi.provider, bi.created_at, bi.updated_at
  FROM bot_instances bi WHERE bi.provider = 'slack';
SQL
    add_index :events, :bot_user_id, unique: true, where: "event_type = 'user-added'", name: "unique-bot-user-id-user-added"
  end

  def down
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_id"
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_id
                   CHECK (
                           (
                             (event_attributes->>'id') IS NOT NULL
                             AND length(event_attributes->>'id') > 0
                             AND provider = 'kik'
                           )
                           OR
                             provider IN ('facebook', 'slack')
                         )"

    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (
                          (
                            event_type IN ('user_added', 'bot-installed', 'bot_disabled', 'added_to_channel', 'message', 'message_reaction')
                          ) AND provider = 'slack'
                          OR (
                            (
                              event_type IN ('message', 'messaging_postbacks', 'messaging_optins', 'account_linking', 'messaging_referrals', 'message:image-uploaded', 'message:audio-uploaded', 'message:video-uploaded', 'message:file-uploaded', 'message:location-sent')
                            ) AND provider = 'facebook'
                          ) AND bot_user_id IS NOT NULL
                          OR (
                            (
                              event_type IN ('message', 'message:image-uploaded', 'message:video-uploaded', 'message:link-uploaded', 'message:scanned-data', 'message:sticker-uploaded', 'message:friend-picker-chosen', 'message:is-typing', 'message:start-chatting')
                            ) AND provider = 'kik'
                          ) AND bot_user_id IS NOT NULL
                        )"
    remove_index :events, name: "unique-bot-user-id-user-added"
  end
end
