class CreateFunnels < ActiveRecord::Migration
  def up
    create_table :funnels do |t|
      t.references :bot, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string     :uid, null: false
      t.string     :name, null: false
      t.jsonb      :dashboards

      t.timestamps null: false
    end

    execute "ALTER TABLE funnels ALTER COLUMN dashboards SET DEFAULT '[]'::JSONB"

    add_index :funnels, :uid, unique: true
  end

  def down
    drop_table :funnels
  end
end
