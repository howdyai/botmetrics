class AddStateToBotInstance < ActiveRecord::Migration
  def up
    add_column :bot_instances, :state, :string, null: false, default: 'pending'
    remove_column :bot_instances, :enabled
    change_column_null :bot_instances, :uid, true
    execute "ALTER TABLE bot_instances ADD CONSTRAINT uid_set_if_not_pending CHECK ((state = 'pending') OR (state = 'enabled' AND uid IS NOT NULL) OR (state = 'disabled' AND uid IS NOT NULL))"
  end

  def down
    remove_column :bot_instances, :state
    add_column :bot_instances, :enabled, :boolean, default: false
    change_column_null :bot_instances, :uid, false
  end
end
