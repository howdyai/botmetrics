class ModifyRolledupEventsIndex < ActiveRecord::Migration
  def up
    remove_index :rolledup_events, [:dashboard_id, :created_at]
    add_index :rolledup_events, [:created_at, :dashboard_id]
  end

  def down
    remove_index :rolledup_events, [:created_at, :dashboard_id]
    add_index :rolledup_events, [:dashboard_id, :created_at]
  end
end
