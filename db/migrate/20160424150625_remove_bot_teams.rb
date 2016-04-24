class RemoveBotTeams < ActiveRecord::Migration
  def up
    remove_reference :bot_users, :bot_team
    drop_table :bot_teams
  end

  def down
    create_table :bot_teams do |t|
      t.string :uid, null: false
      t.json   :team_attributes
      t.references :bot_instance, null: false, foreign_key: true
      t.timestamps null: false
    end

    execute "ALTER TABLE bot_teams ALTER COLUMN team_attributes SET DEFAULT '{}'::JSON"
    add_index :bot_teams, :bot_instance_id
    add_reference :bot_users, :bot_team, null: false, foreign_key: true
    add_index :bot_users, :bot_team_id
  end
end
