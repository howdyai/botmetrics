class UpdateFacebookEventType < ActiveRecord::Migration
  def up
    execute <<-SQL
  UPDATE events
  SET event_type = CASE (event_attributes->'attachments'->0->>'type')::text
                     WHEN 'image'    THEN 'message:image-uploaded'
                     WHEN 'video'    THEN 'message:video-uploaded'
                     WHEN 'audio'    THEN 'message:audio-uploaded'
                     WHEN 'file'     THEN 'message:file-uploaded'
                     WHEN 'location' THEN 'message:location-sent'
                     ELSE                 'message'
                   END
  WHERE events.provider = 'facebook' AND (event_attributes->'attachments')::text IS NOT NULL;
SQL
  end

  def down
    execute <<-SQL
  UPDATE events
  SET event_type = 'message'
  WHERE events.provider = 'facebook' AND (event_attributes->'attachments')::text IS NOT NULL;
SQL
  end
end
