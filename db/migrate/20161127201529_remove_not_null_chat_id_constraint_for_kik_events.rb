class RemoveNotNullChatIdConstraintForKikEvents < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events DROP CONSTRAINT validate_attributes_chat_id"
  end

  def down
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
  end
end
