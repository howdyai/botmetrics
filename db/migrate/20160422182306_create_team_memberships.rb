class CreateTeamMemberships < ActiveRecord::Migration
  def change
    create_table :team_memberships do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :membership_type, null: false, default: 'member'

      t.timestamps null: false
    end

    add_index :team_memberships, [:user_id, :team_id], unique: true
  end
end
