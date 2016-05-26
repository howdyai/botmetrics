class RenameWebhookHistoriesToWebhookEvents < ActiveRecord::Migration
  def change
    rename_table :webhook_histories, :webhook_events
  end
end
