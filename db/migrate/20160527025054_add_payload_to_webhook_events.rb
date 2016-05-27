class AddPayloadToWebhookEvents < ActiveRecord::Migration
  def change
    add_column :webhook_events, :payload, :jsonb, default: {}
  end
end
