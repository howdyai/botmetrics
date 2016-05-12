require 'spec_helper'

RSpec.describe Event do
  describe 'associations' do
    it { should belong_to :bot_instance }
    it { should belong_to :user }
  end

  describe 'validations' do
    context 'regular validations' do
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

    context 'reaction is not null' do
      let!(:user)  { create :bot_user }
      let!(:event) { create :event, user: user, event_attributes: { 'timestamp': '123456789.0' }, provider: 'slack' }

      it "should be invalid if event_type = 'message_reaction' and reaction is NULL" do
        event.event_type = 'message_reaction'
        event.event_attributes[:channel] = 'CDEAD1'
        event.event_attributes[:timestamp] = '123456789.0'
        expect(event).to_not be_valid
        expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
      end

      it "should be valid if event_type = 'message_reaction' and reaction is NOT NULL" do
        event.event_type = 'message_reaction'
        event.event_attributes[:channel] = 'CDEAD1'
        event.event_attributes[:reaction] = ':+1:'
        event.event_attributes[:timestamp] = '123456789.0'
        expect(event).to_not be_valid
        expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
      end
    end

    context 'channel is not null' do
      let!(:user)  { create :bot_user }
      let!(:event) { create :event, user: user, event_attributes: { 'timestamp': '123456789.0' }, provider: 'slack' }

      it "should be invalid if event_type = 'message' and channel IS NULL" do
        event.event_type = 'message'
        expect(event).to_not be_valid
        expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
      end

      it "should be invalid if event_type = 'message_reaction' and channel IS NULL" do
        event.event_type = 'message'
        expect(event).to_not be_valid
        expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
      end

      it "should be valid if event_type = 'message' and channel IS NOT NULL" do
        event.event_type = 'message'
        event.event_attributes['channel'] = 'CABCDEAD1'
        expect(event).to be_valid
      end

      it "should be valid if event_type = 'message_reaction' and channel IS NOT NULL" do
        event.event_type = 'message_reaction'
        event.event_attributes['channel'] = 'CABCDEAD1'
        expect(event).to be_valid
      end
    end

  end
end
