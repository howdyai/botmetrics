class AddEventTypeAndQueryOptionsToDashboards < ActiveRecord::Migration
  def up
    add_column :dashboards, :event_type, :string
    add_column :dashboards, :query_options, :jsonb

    execute "ALTER TABLE dashboards ALTER COLUMN event_type SET DEFAULT '{}'::JSONB"

    Dashboard.find_each do |dashboard|
      dashboard.set_event_type_and_query_options!
      dashboard.save!
    end

    execute <<-SQL
      ALTER TABLE dashboards ADD CONSTRAINT check_if_event_type_is_null
        CHECK (
                (
                  event_type IS NOT NULL AND dashboard_type <> 'custom'
                ) OR
                dashboard_type = 'custom'
              )
SQL

    add_index :dashboards, [:bot_id, :event_type, :query_options], unique: true
  end

  def down
    remove_column :dashboards, :event_type, :string
    remove_column :dashboards, :query_options, :jsonb
  end
end
