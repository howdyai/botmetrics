class AddBotReferenceToQuerySet < ActiveRecord::Migration
  def change
    add_reference :query_sets, :bot, index: true
  end
end
