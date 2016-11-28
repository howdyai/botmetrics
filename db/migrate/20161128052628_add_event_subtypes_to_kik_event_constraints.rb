class AddEventSubtypesToKikEventConstraints < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_sub_type"
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
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (
                          (
                            event_type IN ('user_added', 'bot_disabled', 'added_to_channel', 'message', 'message_reaction')
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
  end

  def down
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
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
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (
                          (
                            event_type IN ('user_added', 'bot_disabled', 'added_to_channel', 'message', 'message_reaction')
                          ) AND provider = 'slack'
                          OR (
                            (
                              event_type IN ('message', 'messaging_postbacks', 'messaging_optins', 'account_linking', 'messaging_referrals', 'message:image-uploaded', 'message:audio-uploaded', 'message:video-uploaded', 'message:file-uploaded', 'message:location-sent')
                            ) AND provider = 'facebook'
                          ) AND bot_user_id IS NOT NULL
                          OR (
                            (
                              event_type = 'message'
                            ) AND provider = 'kik'
                          ) AND bot_user_id IS NOT NULL
                        )"
  end
end
