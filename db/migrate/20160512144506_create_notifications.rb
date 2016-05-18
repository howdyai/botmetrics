class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.text :content, null: false
      t.text :bot_user_ids, array: true, default: []

      t.references :bot, index: true, foreign_key: true

      t.timestamps
    end
  end
end
