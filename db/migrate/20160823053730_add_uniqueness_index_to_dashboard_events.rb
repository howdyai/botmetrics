class AddUniquenessIndexToDashboardEvents < ActiveRecord::Migration
  def change
    add_index :dashboard_events, [:event_id, :dashboard_id], unique: true
  end
end
