require 'spec_helper'

describe BotTeam do
  describe 'validations' do
    subject { create :bot_team }
    it { should validate_presence_of :uid }
    it { should validate_presence_of :bot_instance_id }
  end

  describe 'associations' do
    it { should belong_to :bot_instance }
    it { should have_many :bot_users }
  end
end
