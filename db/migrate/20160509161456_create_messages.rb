class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.jsonb   :message_attributes, null: false, default: {}
      t.string  :user
      t.text    :text
      t.text    :attachments
      t.string  :response

      t.references :bot_instance

      t.timestamps
    end
  end
end
