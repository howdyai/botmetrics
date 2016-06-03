class AddNonNullConstraintsToQueriesAndQuerySets < ActiveRecord::Migration
  def change
    change_column_null :queries, :field, false
    change_column_null :queries, :method, false
    change_column_null :query_sets, :name, false
    change_column_null :query_sets, :provider, false
  end
end
