class AddInstanceAttributesToBotInstance < ActiveRecord::Migration
  def change
    add_column :bot_instances, :instance_attributes, :jsonb, null: false
    execute "ALTER TABLE bot_instances ALTER COLUMN instance_attributes SET DEFAULT '{}'::JSONB"
  end
end
