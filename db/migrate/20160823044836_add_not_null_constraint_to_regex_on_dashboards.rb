class AddNotNullConstraintToRegexOnDashboards < ActiveRecord::Migration
  def up
    execute """
ALTER TABLE dashboards ADD CONSTRAINT regex_not_null_when_dashboard_type_custom
CHECK (
  (
    dashboard_type = 'custom' AND
    (regex IS NOT NULL AND regex <> '')
  ) OR
  (
    dashboard_type <> 'custom'
  )
)
"""
  end

  def down

  end
end
