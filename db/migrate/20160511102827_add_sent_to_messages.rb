class AddSentToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :sent, :boolean, default: false
  end
end
