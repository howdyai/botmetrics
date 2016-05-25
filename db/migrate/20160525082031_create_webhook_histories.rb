class CreateWebhookHistories < ActiveRecord::Migration
  def change
    create_table :webhook_histories do |t|
      t.integer :code
      t.decimal :elapsed_time, precision: 15, scale: 10, default: 0.0 

      t.integer :bot_id, null: false

      t.timestamps null: false
    end

    add_foreign_key :webhook_histories, :bots, on_delete: :cascade
  end
end
