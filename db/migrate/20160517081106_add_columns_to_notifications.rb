class AddColumnsToNotifications < ActiveRecord::Migration
  def change
    change_table :notifications do |t|
      t.string  :scheduled_at
    end
  end
end
