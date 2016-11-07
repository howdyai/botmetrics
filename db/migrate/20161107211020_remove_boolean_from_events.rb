class RemoveBooleanFromEvents < ActiveRecord::Migration
  def change
    remove_column :events, :boolean, :boolean, default: false
  end
end
