class ChangeResponseToJsonb < ActiveRecord::Migration
  def change
    remove_column :messages, :response, :jsonb
    add_column :messages, :response, :jsonb, default: {}
  end
end
