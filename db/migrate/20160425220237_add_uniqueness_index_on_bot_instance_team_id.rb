class AddUniquenessIndexOnBotInstanceTeamId < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances(uid, (instance_attributes->'team_id')) WHERE bot_instances.provider = 'slack'"
  end

  def down
    execute "DROP INDEX bot_instances_team_id_uid"
  end
end
