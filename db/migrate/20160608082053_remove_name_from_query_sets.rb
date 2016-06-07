class RemoveNameFromQuerySets < ActiveRecord::Migration
  def change
    remove_column :query_sets, :name, :string, null: false
  end
end
