require 'spec_helper'

describe BotUser do
  describe 'validations' do
    subject { create :bot_user }

    it { should validate_presence_of :uid }
    it { should validate_presence_of :bot_team_id }
    it { should validate_presence_of :membership_type }
  end

  describe 'associations' do
    it { should belong_to :bot_team }
  end
end
