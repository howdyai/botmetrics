class BackfillBotUsersWithUserAddedEvent < ActiveRecord::Migration
  def up
    execute <<-SQL
  INSERT INTO events(bot_instance_id, bot_user_id, provider, event_type, created_at, updated_at)
  SELECT
    u.bot_instance_id, u.id, u.provider, 'user-added', u.created_at, u.updated_at
  FROM bot_users u;
SQL
  end

  def down
    execute <<-SQL
  DELETE FROM events WHERE event_type = 'user-added';
SQL
  end
end
