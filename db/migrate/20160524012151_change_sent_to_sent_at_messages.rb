class ChangeSentToSentAtMessages < ActiveRecord::Migration
  def change
    remove_column :messages, :sent
    add_column :messages, :sent_at, :datetime
  end
end
