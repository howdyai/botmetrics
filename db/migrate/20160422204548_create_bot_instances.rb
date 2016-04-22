class CreateBotInstances < ActiveRecord::Migration
  def change
    create_table :bot_instances do |t|
      t.string :token, null: false
      t.string :uid, null: false
      t.references :bot, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :bot_instances, :bot_id
    add_index :bot_instances, :token, unique: true
    add_index :bot_instances, :uid, unique: true
  end
end
