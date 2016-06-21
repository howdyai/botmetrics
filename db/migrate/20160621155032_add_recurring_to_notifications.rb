class AddRecurringToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :recurring, :boolean, default: false, null: false
  end
end
