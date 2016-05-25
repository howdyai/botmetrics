class AddEmailPreferencesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_preferences, :jsonb, default: {}
  end
end
