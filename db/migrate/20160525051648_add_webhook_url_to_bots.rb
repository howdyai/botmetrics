class AddWebhookUrlToBots < ActiveRecord::Migration
  def change
    add_column :bots, :webhook_url, :string
  end
end
