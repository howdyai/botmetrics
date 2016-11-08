class CreateShortLinks < ActiveRecord::Migration
  def change
    create_table :shortened_links do |t|
      t.references :bot_user, index: true, foreign_key: true
      t.references :bot_instance, index: true, foreign_key: true
      t.string :url, null:false
      t.string :slug, null:false
      t.integer :use_count
      t.timestamps
    end
    add_index :shortened_links, :slug, unique:true
  end

end
