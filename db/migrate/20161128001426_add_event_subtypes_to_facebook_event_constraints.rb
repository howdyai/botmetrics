class AddEventSubtypesToFacebookEventConstraints < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
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

  def down
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS valid_event_type_on_events"
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events
                   CHECK (
                          (
                            event_type IN ('user_added', 'bot_disabled', 'added_to_channel', 'message', 'message_reaction')
                          ) AND provider = 'slack'
                          OR (
                            (
                              event_type IN ('message', 'messaging_postbacks', 'messaging_optins', 'account_linking', 'messaging_referrals')
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
