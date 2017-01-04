class AddIndexesOnRolledupEventsForPathAnalysis < ActiveRecord::Migration
  def change
    add_index :rolledup_events, [:created_at, :dashboard_id, :bot_user_id], name: "index_rolledup_events_on_created_at_did_buid"
    add_index :rolledup_events, [:dashboard_id, :bot_user_id]
  end
end
