class CreateDashboards < ActiveRecord::Migration
  def change
    create_table :dashboards do |t|
      t.string      :name, null: false
      t.string      :provider, null: false
      t.boolean     :default, default: false, null: false
      t.boolean     :enabled, default: true, null: false
      t.string      :uid, null: false

      t.string      :regex
      t.references  :bot, index: true, foreign_key: true, null: false
      t.references  :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end

    add_index :dashboards, [:name, :bot_id], unique: true
    add_index :dashboards, :uid, unique: true
  end
end
