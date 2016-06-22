class BotInstanceUniquenessIndexScopedToTeamIdAndState < ActiveRecord::Migration
  def up
    execute "DROP INDEX bot_instances_team_id_uid"
    execute "CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances(uid, (instance_attributes->'team_id')) WHERE bot_instances.provider = 'slack' AND bot_instances.state = 'enabled'"
  end

  def down
    execute "DROP INDEX bot_instances_team_id_uid"
    execute "CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances(uid, (instance_attributes->'team_id')) WHERE bot_instances.provider = 'slack'"
  end
end
