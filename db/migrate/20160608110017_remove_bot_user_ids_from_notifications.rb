class RemoveBotUserIdsFromNotifications < ActiveRecord::Migration
  def change
    remove_column :notifications, :bot_user_ids, :text, array: true, default: []
  end
end
