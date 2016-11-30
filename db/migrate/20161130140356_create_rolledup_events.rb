class CreateRolledupEvents < ActiveRecord::Migration
  def change
    create_table :rolledup_events do |t|
      t.integer    :count, limit: 8, default: 0
      t.references :bot_user
      t.references :bot_instance, null: false
      t.references :dashboard, null: false
      t.datetime   :created_at, null: false
    end
  end
end
