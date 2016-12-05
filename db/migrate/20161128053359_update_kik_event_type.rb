class UpdateKikEventType < ActiveRecord::Migration
  def up
    execute <<-SQL
  UPDATE events
  SET event_type = CASE (event_attributes->>'sub_type')::text
                     WHEN 'picture'              THEN 'message:image-uploaded'
                     WHEN 'video'                THEN 'message:video-uploaded'
                     WHEN 'link'                 THEN 'message:link-uploaded'
                     WHEN 'scan-data'            THEN 'message:scanned-data'
                     WHEN 'sticker-uploaded'     THEN 'message:sticker-uploaded'
                     WHEN 'friend-picker-chosen' THEN 'message:friend-picker-chosen'
                     WHEN 'is-typing'            THEN 'message:is-typing'
                     WHEN 'start-chatting'       THEN 'message:start-chatting'
                     ELSE                             'message'
                   END
  WHERE events.provider = 'kik' AND (event_attributes->'sub_type')::text IS NOT NULL;
SQL
  end

  def down
    execute <<-SQL
  UPDATE events
  SET event_type = 'message'
  WHERE events.provider = 'kik' AND (event_attributes->'sub_type')::text IS NOT NULL;
SQL

  end
end
