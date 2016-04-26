class AddIsFromBotToEvents < ActiveRecord::Migration
  def change
    add_column :events, :is_from_bot, :boolean, default: false, null: false
  end
end
