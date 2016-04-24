class AddProviderToBotInstance < ActiveRecord::Migration
  def up
    add_column :bot_instances, :provider, :string, null: false
    execute "ALTER TABLE bot_instances ADD CONSTRAINT valid_provider_on_bot_instances CHECK (provider = 'slack' OR provider = 'kik' OR provider = 'facebook' OR provider = 'telegram')"
  end

  def down
    remove_column :bot_instances, :provider
  end
end
