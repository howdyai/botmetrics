class AddInstanceAttributesConstraintsOnBi < ActiveRecord::Migration
  def up
    execute "ALTER TABLE bot_instances ADD CONSTRAINT validate_attributes_team_id CHECK (((instance_attributes->>'team_id') IS NOT NULL AND length(instance_attributes->>'team_id') > 0 AND provider = 'slack' AND state <> 'pending') OR (state = 'pending' AND instance_attributes IS NOT NULL))"
    execute "ALTER TABLE bot_instances ADD CONSTRAINT validate_attributes_team_name CHECK (((instance_attributes->>'team_name') IS NOT NULL AND length(instance_attributes->>'team_name') > 0 AND provider = 'slack' AND state <> 'pending') OR (state = 'pending' AND instance_attributes IS NOT NULL))"
    execute "ALTER TABLE bot_instances ADD CONSTRAINT validate_attributes_team_url CHECK (((instance_attributes->>'team_url') IS NOT NULL AND length(instance_attributes->>'team_url') > 0 AND provider = 'slack' AND state <> 'pending') OR (state = 'pending' AND instance_attributes IS NOT NULL))"
  end

  def down
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_team_id"
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_team_name"
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_team_url"
  end
end
