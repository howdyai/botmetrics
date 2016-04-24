require 'rails_helper'

describe BotInstance do
  describe 'validations' do
    subject { create :bot_instance }

    it { should validate_presence_of :token }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :uid }
    it { should validate_uniqueness_of :token }
    it { should validate_uniqueness_of :uid }

    it { should allow_value('slack').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('telegram').for(:provider) }
    it { should_not allow_value('test').for(:provider) }
  end

  describe 'associations' do
    it { should belong_to  :bot }
    it { should have_many  :users }
  end
end
