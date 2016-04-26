class AddMixpanelPropertiesToUser < ActiveRecord::Migration
  def change
    add_column :users, :mixpanel_properties, :json
    execute "ALTER TABLE users ALTER COLUMN mixpanel_properties SET DEFAULT '{}'::JSON"
    change_column_null :users, :mixpanel_properties, false
  end
end
