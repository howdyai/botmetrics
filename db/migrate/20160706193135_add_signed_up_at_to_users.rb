class AddSignedUpAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :signed_up_at, :datetime
    User.reset_column_information

    User.find_each do |u|
      u.update_attributes!(signed_up_at: u.created_at)
    end
  end

  def down
    remove_column :users, :signed_up_at
  end
end
