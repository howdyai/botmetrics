class AddIndexOnEventsCreatedAtWhenIsForBotIsTrue < ActiveRecord::Migration
  def change
    add_index :events, :created_at, where: "is_for_bot = 't'"
  end
end
