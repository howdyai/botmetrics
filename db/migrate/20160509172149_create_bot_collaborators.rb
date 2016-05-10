class CreateBotCollaborators < ActiveRecord::Migration
  def change
    create_table :bot_collaborators do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :bot, index: true, foreign_key: true, null: false
      t.string :collaborator_type, null: false

      t.timestamps null: false
    end

    add_index :bot_collaborators, [:user_id, :bot_id], unique: true
  end
end
