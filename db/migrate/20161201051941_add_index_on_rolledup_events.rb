class AddIndexOnRolledupEvents < ActiveRecord::Migration
  def change
    add_index :rolledup_events, [:dashboard_id, :created_at]
  end
end
