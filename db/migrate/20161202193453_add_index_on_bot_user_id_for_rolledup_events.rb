class AddIndexOnBotUserIdForRolledupEvents < ActiveRecord::Migration
  def change
    add_index :rolledup_events, :bot_user_id
  end
end
