require 'rails_helper'

describe Event do
  describe 'associations' do
    it { should belong_to :bot_instance }
    it { should belong_to :user }
  end

  describe 'validations' do
    subject { create :event }

    it { should validate_presence_of :event_type }
    it { should validate_presence_of :bot_instance_id }
    it { should validate_presence_of :provider }

    it { should allow_value('slack').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('telegram').for(:provider) }
    it { should_not allow_value('test').for(:provider) }

    it { should allow_value('user_added').for(:event_type) }
    it { should allow_value('bot_disabled').for(:event_type) }
    it { should allow_value('added_to_channel').for(:event_type) }
    it { should allow_value('message').for(:event_type) }
    it { should allow_value('message_reaction').for(:event_type) }
    it { should_not allow_value('test').for(:event_type) }
  end
end
