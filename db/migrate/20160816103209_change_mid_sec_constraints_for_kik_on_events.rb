class ChangeMidSecConstraintsForKikOnEvents < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_mid"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_seq"

    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_mid
                   CHECK (
                          (
                            (event_attributes->>'mid') IS NOT NULL
                            AND length(event_attributes->>'mid') > 0
                            AND provider = 'facebook'
                            AND event_type = 'message'
                          )
                          OR
                          (
                            provider = 'facebook'
                            AND event_type <> 'message'
                            AND event_attributes IS NOT NULL
                          )
                          OR
                            provider IN ('slack', 'kik')
                         )"

    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_seq
                   CHECK (
                          (
                            (event_attributes->>'seq') IS NOT NULL
                            AND length(event_attributes->>'seq') > 0
                            AND provider = 'facebook'
                            AND event_type = 'message'
                          )
                          OR
                          (
                            provider = 'facebook'
                            AND event_type <> 'message'
                            AND event_attributes IS NOT NULL
                          )
                          OR
                            provider IN ('slack', 'kik')
                         )"
  end

  def down
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_mid"
    execute "ALTER TABLE events DROP CONSTRAINT IF EXISTS validate_attributes_seq"
  end
end
