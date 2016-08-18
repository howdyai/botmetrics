class AddProviderConstraintsOnDashboards < ActiveRecord::Migration
  def up
    execute "ALTER TABLE dashboards ADD CONSTRAINT valid_provider_on_dashboards CHECK (provider = 'slack' OR provider = 'kik' OR provider = 'facebook' OR provider = 'telegram')"
  end

  def down
    execute "ALTER TABLE dashboards DROP CONSTRAINT valid_provider_on_dashboards"
  end
end
