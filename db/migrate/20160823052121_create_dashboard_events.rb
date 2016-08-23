class CreateDashboardEvents < ActiveRecord::Migration
  def change
    create_table :dashboard_events do |t|
      t.references :dashboard, null: false, index: true
      t.references :event, null: false, index: true

      t.timestamps null: false
    end
  end
end
