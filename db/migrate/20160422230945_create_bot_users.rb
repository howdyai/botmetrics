class CreateBotUsers < ActiveRecord::Migration
  def change
    create_table :bot_users do |t|
      t.string     :uid, null: false
      t.json       :user_attributes, null: false
      t.references :bot_team, null: false, foreign_key: true
      t.string     :membership_type, null: false

      t.timestamps null: false
    end

    execute "ALTER TABLE bot_users ALTER COLUMN user_attributes SET DEFAULT '{}'::JSON"
    add_index :bot_users, :bot_team_id
  end
end
