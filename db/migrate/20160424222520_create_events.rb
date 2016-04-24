class CreateEvents < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.string :event_type, null: false
      t.references :bot_instance, index: true, foreign_key: true, null: false
      t.references :bot_user, index: true, foreign_key: true
      t.boolean :is_for_bot, :boolean, null: false, default: false
      t.jsonb :event_attributes, null: false
      t.string :provider, null: false

      t.timestamps null: false
    end

    execute "ALTER TABLE events ALTER COLUMN event_attributes SET DEFAULT '{}'::JSONB"
    execute "ALTER TABLE events ADD CONSTRAINT valid_provider_on_events CHECK (provider = 'slack' OR provider = 'kik' OR provider = 'facebook' OR provider = 'telegram')"
    execute "ALTER TABLE events ADD CONSTRAINT valid_event_type_on_events CHECK (event_type = 'user_added' OR event_type = 'bot_disabled' OR event_type = 'added_to_channel' OR (event_type = 'message' AND bot_user_id IS NOT NULL) OR (event_type = 'message_reaction' AND bot_user_id IS NOT NULL))"
  end

  def down
    drop_table :events
  end
end
