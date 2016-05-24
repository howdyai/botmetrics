class AddUidToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :uid, :string
    add_index  :notifications, :uid, unique: true

    Notification.where(uid: nil).find_each do |notification|
      notification.update(uid: SecureRandom.hex(6))
    end

    change_column :notifications, :uid, :string, null: false
  end
end
