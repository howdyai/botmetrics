class AddUniqueIndexOnBotInstalledBotDisabledConditions < ActiveRecord::Migration
  def up
    add_index :events, [:event_type, :bot_instance_id], unique: true, where: "event_type IN ('bot-installed', 'bot_disabled')"
  end
end
