require 'spec_helper'

RSpec.describe BotCollaborator do
  describe 'validations' do
    subject { create :bot_collaborator }

    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :user_id }
    it { should validate_presence_of :collaborator_type }
    it { should validate_uniqueness_of(:user_id).scoped_to(:bot_id) }
  end

  describe 'associations' do
    it { should belong_to :user }
    it { should belong_to :bot  }
  end
end
