class AddBotInstanceReferenceToBotUsers < ActiveRecord::Migration
  def change
    add_reference :bot_users, :bot_instance, null: false, foreign_key: true
    add_index :bot_users, :bot_instance_id
  end
end
