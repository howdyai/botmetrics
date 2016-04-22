class TeamMembership < ActiveRecord::Base
  belongs_to :team
  belongs_to :user

  validates_presence_of :team_id, :user_id, :membership_type
  validates_uniqueness_of :team_id, scope: :user_id
end
