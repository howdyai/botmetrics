class AddWebhookStatusToBots < ActiveRecord::Migration
  def change
    add_column :bots, :webhook_status, :boolean, default: false
  end
end
