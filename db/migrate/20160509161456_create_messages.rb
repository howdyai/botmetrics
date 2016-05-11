class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string  :provider
      t.jsonb   :message_attributes, null: false, default: {}
      t.text    :text
      t.text    :attachments
      t.string  :response

      t.references :bot_instance

      t.timestamps
    end

    add_index :messages, :bot_instance_id
  end
end
