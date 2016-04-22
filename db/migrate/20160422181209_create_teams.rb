class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :uid, null: false

      t.timestamps null: false
    end

    add_index :teams, :uid, unique: true
  end
end
