class AddEnabledToBots < ActiveRecord::Migration
  def up
    add_column :bots, :enabled, :boolean, default: true
    Bot.update_all(enabled: true)
    change_column_null :bots, :enabled, false
  end

  def down
    remove_column :bots, :enabled, :boolean
  end
end
