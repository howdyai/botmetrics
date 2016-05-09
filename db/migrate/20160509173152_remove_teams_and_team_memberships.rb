class RemoveTeamsAndTeamMemberships < ActiveRecord::Migration
  def change
    remove_reference :bots, :team

    drop_table :team_memberships
    drop_table :teams
  end
end
