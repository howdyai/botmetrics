class AddWebhooksEnabledToBots < ActiveRecord::Migration
  def change
    add_column :bots, :webhooks_enabled, :boolean, default: false
    Bot.update_all(webhooks_enabled: false)
    change_column_null :bots, :webhooks_enabled, false
  end
end
