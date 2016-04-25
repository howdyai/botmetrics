class AddIsImToEvent < ActiveRecord::Migration
  def change
    add_column :events, :is_im, :boolean, default: false, null: false
  end
end
