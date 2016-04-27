class FixConditionalUidConstraint < ActiveRecord::Migration
  def up
    execute "ALTER TABLE bot_instances DROP CONSTRAINT uid_set_if_not_pending"
  end

  def down
    execute "ALTER TABLE bot_instances ADD CONSTRAINT uid_set_if_not_pending CHECK ((state = 'pending') OR (state = 'enabled' AND uid IS NOT NULL) OR (state = 'disabled'))"
  end
end
