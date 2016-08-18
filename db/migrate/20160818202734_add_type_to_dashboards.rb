class AddTypeToDashboards < ActiveRecord::Migration
  def up
    add_column :dashboards, :dashboard_type, :string, null: false
    execute """
ALTER TABLE dashboards ADD CONSTRAINT valid_dashboard_type_on_dashboards
CHECK (
  (
    provider = 'slack' AND (
      dashboard_type = 'bots-installed' OR
      dashboard_type = 'bots-uninstalled' OR
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'custom'
   )
  ) OR
  (
    provider = 'facebook' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'custom'
    )
  ) OR
  (
    provider = 'facebook' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'custom'
    )
  ) OR (
    provider = 'telegram'
  )
)
    """
  end

  def down
    remove_column :dashboards, :dashboard_type
  end
end
