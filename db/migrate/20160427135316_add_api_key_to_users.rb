class AddApiKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_key, :string
    add_index :users, :api_key, unique:true, where: "api_key IS NOT NULL"
  end
end
