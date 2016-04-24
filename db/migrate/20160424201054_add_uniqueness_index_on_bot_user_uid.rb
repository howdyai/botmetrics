class AddUniquenessIndexOnBotUserUid < ActiveRecord::Migration
  def change
    add_index :bot_users, [:uid, :bot_instance_id], unique: true
  end
end
