class AddInstancesScopeAndTimeZoneToQuerySets < ActiveRecord::Migration
  def change
    add_column :query_sets, :instances_scope, :string, null: false
    add_column :query_sets, :time_zone, :string, null: false
  end
end
