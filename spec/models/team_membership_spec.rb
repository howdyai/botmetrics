require 'spec_helper'

describe TeamMembership do
  describe 'validations' do
    subject { create :team_membership }

    it { should validate_presence_of :team_id }
    it { should validate_presence_of :user_id }
    it { should validate_presence_of :membership_type }
    it { should validate_uniqueness_of(:team_id).scoped_to(:user_id) }
  end

  describe 'associations' do
    it { should belong_to :team }
    it { should belong_to :user }
  end
end
