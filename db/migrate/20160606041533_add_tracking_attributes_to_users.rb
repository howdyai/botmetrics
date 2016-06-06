class AddTrackingAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tracking_attributes, :jsonb, default: {}
  end
end
