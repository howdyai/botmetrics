class AddScheduledAtToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :scheduled_at, :datetime
  end
end
