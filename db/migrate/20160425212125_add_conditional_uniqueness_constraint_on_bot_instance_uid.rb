class AddConditionalUniquenessConstraintOnBotInstanceUid < ActiveRecord::Migration
  def up
    remove_index :bot_instances, :uid
    add_index :bot_instances, :uid, unique: true, where: "uid IS NOT NULL", name: 'unique_bot_instance_uid'
  end

  def down
    remove_index :bot_instances, :uid, name: 'unique_bot_instance_uid'
    add_index :bot_instances, :uid, unique: true
  end
end
