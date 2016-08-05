class AddUniquenessIndexOnMsgIdAndSeqIdOnEvents < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX events_mid_seq_facebook ON events((event_attributes->'mid'), (event_attributes->'seq')) WHERE events.provider = 'facebook' AND events.event_type = 'message'"
  end

  def down
    execute "DROP INDEX events_mid_seq_facebook"
  end
end
