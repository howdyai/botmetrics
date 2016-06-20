class AddLastInteractedWithBotAndBotInteractionCount < ActiveRecord::Migration
  def change
    add_column :bot_users, :last_interacted_with_bot_at, :datetime
    add_column :bot_users, :bot_interaction_count, :integer, default: 0

    BotUser.update_all(bot_interaction_count: 0)
    change_column_null :bot_users, :bot_interaction_count, false
  end
end
