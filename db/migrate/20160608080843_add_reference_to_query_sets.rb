class AddReferenceToQuerySets < ActiveRecord::Migration
  def change
    add_reference :query_sets, :notification, index: true
  end
end
