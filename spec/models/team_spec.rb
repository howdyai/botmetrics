require 'spec_helper'

describe Team do
  describe 'validations' do
    subject { create :team }

    it { should validate_presence_of :name }
    it { should validate_uniqueness_of :uid }
  end

  describe 'associations' do
    it { should have_many :team_memberships }
    it { should have_many(:members).through(:team_memberships) }
  end
end
