class AddReactionConstraintsOnEvent < ActiveRecord::Migration
  def up
    execute "ALTER TABLE events ADD CONSTRAINT validate_attributes_reaction CHECK (((event_attributes->>'reaction') IS NOT NULL AND length(event_attributes->>'reaction') > 0 AND provider = 'slack' AND event_type = 'message_reaction') OR (provider = 'slack' AND event_type <> 'message_reaction' AND event_attributes IS NOT NULL))"
  end

  def down
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_reaction"
  end
end
