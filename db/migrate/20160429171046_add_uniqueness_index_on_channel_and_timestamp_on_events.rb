class AddUniquenessIndexOnChannelAndTimestampOnEvents < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX events_channel_timestamp_message_slack ON events((event_attributes->'timestamp'), (event_attributes->'channel')) WHERE events.provider = 'slack' AND events.event_type = 'message'"
  end

  def down
    execute "DROP INDEX events_channel_timestamp_message_slack"
  end
end
