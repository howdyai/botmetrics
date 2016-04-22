require 'rails_helper'

describe BotInstance do
  describe 'validations' do
    subject { create :bot_instance }

    it { should validate_presence_of :token }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :uid }
    it { should validate_uniqueness_of :token }
    it { should validate_uniqueness_of :uid }
  end

  describe 'associations' do
    it { should belong_to :bot }
    it { should have_one  :bot_team }
  end
end
