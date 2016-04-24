class AddProviderToBotUser < ActiveRecord::Migration
  def up
    add_column :bot_users, :provider, :string, null: false
    execute "ALTER TABLE bot_users ADD CONSTRAINT valid_provider_on_bot_users CHECK (provider = 'slack' OR provider = 'kik' OR provider = 'facebook' OR provider = 'telegram')"
  end

  def down
    remove_column :bot_users, :provider
  end
end
