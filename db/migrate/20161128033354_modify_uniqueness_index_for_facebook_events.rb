class ModifyUniquenessIndexForFacebookEvents < ActiveRecord::Migration
  def up
    execute "DROP INDEX events_mid_seq_facebook"
    execute <<-SQL
      CREATE UNIQUE INDEX events_mid_seq_facebook ON events((event_attributes->'mid'), (event_attributes->'seq'))
      WHERE events.provider = 'facebook' AND
      (
        events.event_type = 'message' OR
        events.event_type = 'message:image-uploaded' OR
        events.event_type = 'message:video-uploaded' OR
        events.event_type = 'message:file-uploaded' OR
        events.event_type = 'message:location-sent' OR
        events.event_type = 'message:audio-uploaded'
      )
SQL
  end

  def down
    execute "DROP INDEX events_mid_seq_facebook"
    execute "CREATE UNIQUE INDEX events_mid_seq_facebook ON events((event_attributes->'mid'), (event_attributes->'seq')) WHERE events.provider = 'facebook' AND events.event_type = 'message'"
  end
end
