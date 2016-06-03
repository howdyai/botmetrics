class UpdateColumnsQueries < ActiveRecord::Migration
  def change
    add_column    :queries, :provider, :string
    remove_column :queries, :type, :string
  end
end
