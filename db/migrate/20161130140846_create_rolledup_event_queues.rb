class CreateRolledupEventQueues < ActiveRecord::Migration
  def change
    create_table :rolledup_event_queue do |t|
      t.integer    :diff, limit: 8, default: 1
      t.references :bot_user
      t.references :bot_instance, null: false
      t.references :dashboard, null: false
      t.datetime   :created_at, null: false
    end
  end
end
