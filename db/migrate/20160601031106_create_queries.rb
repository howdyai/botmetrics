class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :type
      t.string :field
      t.string :method
      t.string :value
      t.references :query_set, index: true

      t.timestamps
    end
  end
end
