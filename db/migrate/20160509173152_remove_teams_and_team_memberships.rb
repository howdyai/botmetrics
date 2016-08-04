class RemoveTeamsAndTeamMemberships < ActiveRecord::Migration
  def change
    remove_reference :bots, :team

    drop_table :team_memberships if ActiveRecord::Base.connection.table_exists? 'team_memberships'
    drop_table :teams if ActiveRecord::Base.connection.table_exists? 'teams'
  end
end
