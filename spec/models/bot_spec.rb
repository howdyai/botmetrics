require 'spec_helper'

describe Bot do
  describe 'validations' do
    subject { create :bot }
    it { should validate_presence_of :name }
    it { should validate_presence_of :provider }
    it { should validate_uniqueness_of :uid }

    it { should allow_value('slack').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('telegram').for(:provider) }
    it { should_not allow_value('test').for(:provider) }
  end

  describe 'associations' do
    it { should have_many :instances }
    it { should have_many :bot_collaborators }
    it { should have_many(:collaborators).through(:bot_collaborators) }
    it { should have_many(:owners).through(:bot_collaborators) }
  end
end
