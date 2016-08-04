class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :provider, null: false
      t.references :team, null: false

      t.timestamps null: false
    end

    add_index :bots, :uid, unique: true
    add_index :bots, :team_id
  end
end
