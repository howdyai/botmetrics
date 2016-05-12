class AddColumnsToMessages < ActiveRecord::Migration
  def change
    rename_column :messages, :sent, :success

    change_table :messages do |t|
      t.references :notification, index: true, foreign_key: true
      t.boolean :sent, default: false
    end
  end
end
