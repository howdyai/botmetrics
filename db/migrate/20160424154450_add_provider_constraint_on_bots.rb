class AddProviderConstraintOnBots < ActiveRecord::Migration
  def up
    execute "ALTER TABLE bots ADD CONSTRAINT valid_provider_on_bots CHECK (provider = 'slack' OR provider = 'kik' OR provider = 'facebook' OR provider = 'telegram')"
  end
end
