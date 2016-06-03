class RemoveProviderFromQuerySets < ActiveRecord::Migration
  def change
    remove_column :query_sets, :provider, :string
  end
end
