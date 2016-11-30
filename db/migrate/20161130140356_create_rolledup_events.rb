class CreateRolledupEvents < ActiveRecord::Migration
  def change
    create_table :rolledup_events do |t|
      t.integer    :count, limit: 8, default: 0
      t.references :bot_user
      t.references :bot_instance, null: false
      t.references :dashboard, null: false
      t.datetime   :created_at, null: false
      t.string     :bot_instance_id_bot_user_id, null: false
    end

    add_index :rolledup_events, [:bot_instance_id_bot_user_id, :dashboard_id, :created_at], unique: true, name: 'rolledup_events_unique_key'
  end
end
