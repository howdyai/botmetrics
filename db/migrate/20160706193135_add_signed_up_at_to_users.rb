class AddSignedUpAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :signed_up_at, :datetime
    User.find_each { |u| u.update_attribute(:signed_up_at, u.created_at) }
  end

  def down
    remove_column :users, :signed_up_at
  end
end
