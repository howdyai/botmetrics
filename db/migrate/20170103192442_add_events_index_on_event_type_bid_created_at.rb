class AddEventsIndexOnEventTypeBidCreatedAt < ActiveRecord::Migration
  def change
    add_index :events, [:event_type, :bot_instance_id, :created_at]
    add_index :events, [:bot_user_id, :created_at]
  end
end
