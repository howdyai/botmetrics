class AddReadAndDeliveredToEvents < ActiveRecord::Migration
  def change
    add_column :events, :has_been_delivered, :boolean, default: false
    add_column :events, :has_been_read, :boolean, default: false

    Event.where(provider: 'slack', event_type: %w(message message_reaction)).update_all(has_been_read: true, has_been_delivered: true)
  end
end
