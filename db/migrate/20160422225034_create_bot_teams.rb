class CreateBotTeams < ActiveRecord::Migration
  def change
    create_table :bot_teams do |t|
      t.string :uid, null: false
      t.json   :team_attributes
      t.references :bot_instance, null: false, foreign_key: true
      t.timestamps null: false
    end

    execute "ALTER TABLE bot_teams ALTER COLUMN team_attributes SET DEFAULT '{}'::JSON"
    add_index :bot_teams, :bot_instance_id
  end
end
