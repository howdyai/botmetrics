class AddFirstReceivedEventAtToBots < ActiveRecord::Migration
  def change
    add_column :bots, :first_received_event_at, :datetime
  end
end
