class AddSlackInviteAttributesToUser < ActiveRecord::Migration
  def change
    add_column :users, :invited_to_slack_at, :datetime
    add_column :users, :slack_invite_response, :jsonb
  end
end
