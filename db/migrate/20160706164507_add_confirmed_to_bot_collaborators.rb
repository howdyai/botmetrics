class AddConfirmedToBotCollaborators < ActiveRecord::Migration
  def up
    add_column :bot_collaborators, :confirmed_at, :datetime
    BotCollaborator.reset_column_information

    BotCollaborator.find_each do |bc|
      bc.update_attribute(:confirmed_at, bc.user.created_at)
    end
  end

  def down
    remove_column :bot_collaborators, :confirmed_at, :datetime
  end
end
