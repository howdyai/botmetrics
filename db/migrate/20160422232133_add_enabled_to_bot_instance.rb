class AddEnabledToBotInstance < ActiveRecord::Migration
  def change
    add_column :bot_instances, :enabled, :boolean, default: false
  end
end
