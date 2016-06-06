class UpdateColumnsQueries < ActiveRecord::Migration
  def change
    add_column    :queries, :provider, :string, null: false
    remove_column :queries, :type, :string
  end
end
