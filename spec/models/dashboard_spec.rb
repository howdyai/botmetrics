require 'rails_helper'

RSpec.describe Dashboard, type: :model do
  describe 'validations' do
    subject { create :dashboard }

    it { should validate_presence_of :name }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :user_id }
    it { should validate_presence_of :provider }
    it { should validate_uniqueness_of :uid }
    it { should validate_uniqueness_of(:name).scoped_to(:bot_id) }

    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('slack').for(:provider) }
    it { should_not allow_value('abcdef').for(:provider) }
  end

  describe 'associations' do
    it { should belong_to :bot }
    it { should belong_to :user }
  end
end
