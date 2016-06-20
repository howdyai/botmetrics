class AddTextToEvents < ActiveRecord::Migration
  def change
    add_column :events, :text, :text
  end
end
