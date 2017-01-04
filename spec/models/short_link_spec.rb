require 'rails_helper'

RSpec.describe ShortLink, type: :model do
  describe 'validations' do
    it { should validate_presence_of :url }
    it { should validate_presence_of :bot_user_id }
    it { should validate_presence_of :bot_instance_id }
  end

  describe 'associations' do
    it { should belong_to :bot_instance }
    it { should belong_to :bot_user }
  end
end
