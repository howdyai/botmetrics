class AddColumnsToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :min_value, :string
    add_column :queries, :max_value, :string
  end
end
