require 'spec_helper'

describe User do
  describe 'associations' do
    it { should have_many :team_memberships }
    it { should have_many(:teams).through(:team_memberships) }
    it { should have_many :bot_collaborators }
    it { should have_many(:bots).through(:bot_collaborators) }
  end
end
