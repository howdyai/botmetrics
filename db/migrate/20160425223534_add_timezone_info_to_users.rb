class AddTimezoneInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :timezone, :string, null: false
    add_column :users, :timezone_utc_offset, :integer, null: false
  end
end
