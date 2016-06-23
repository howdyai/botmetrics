class FixBotInstanceUidIndex < ActiveRecord::Migration
  def up
    remove_index :bot_instances, name: 'unique_bot_instance_uid'
    execute "DROP INDEX bot_instances_team_id_uid"
    execute "CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances(uid, (instance_attributes->'team_id')) WHERE bot_instances.provider = 'slack' AND bot_instances.state = 'enabled' AND bot_instances.uid IS NOT NULL"
  end

  def down
    add_index :bot_instances, :uid, unique: true, where: "uid IS NOT NULL", name: 'unique_bot_instance_uid'
    execute "DROP INDEX bot_instances_team_id_uid"
    execute "CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances(uid, (instance_attributes->'team_id')) WHERE bot_instances.provider = 'slack' AND bot_instances.state = 'enabled'"
  end
end
