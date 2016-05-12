require 'rails_helper'

RSpec.describe Messages::Slack do
  context 'validations' do
    it { is_expected.to validate_presence_of :team_id }

    context 'when channel is blank' do
      subject { Messages::Slack.new(channel: nil) }

      it { is_expected.to validate_presence_of :user }
    end

    context 'when user is blank' do
      subject { Messages::Slack.new(user: nil) }

      it { is_expected.to validate_presence_of :channel }
    end

    context 'when text is blank' do
      subject { Messages::Slack.new(text: nil) }

      it { is_expected.to validate_presence_of :attachments }
    end

    context 'when attachments is blank' do
      subject { Messages::Slack.new(attachments: nil) }

      it { is_expected.to validate_presence_of :text }
    end
  end

  describe '#model_params' do
    let(:message) { Messages::Slack.new(team_id: 'T1234', user: 'U5678', text: 'OK!') }

    it 'prepares model params' do
      message  = Messages::Slack.new(team_id: 'T1234', user: 'U5678', text: 'OK!')
      expected = { message_attributes: { team_id: 'T1234' , user: 'U5678' }, text: 'OK!' }

      expect(message.model_params).to eq expected
    end

    it 'prepares model params' do
      message  = Messages::Slack.new(team_id: 'T1234', channel: 'C5678', text: 'OK!')
      expected = { message_attributes: { team_id: 'T1234', channel: 'C5678' }, text: 'OK!' }

      expect(message.model_params).to eq expected
    end
  end

  describe '#save_for' do
    let(:bot_instance) { create(:bot_instance, provider: 'slack') }

    context 'valid' do
      let(:message) { Messages::Slack.new(team_id: 'T1234', channel: 'C5678', text: 'OK!') }

      it 'saves a message in the DB' do
        expect {
          message.save_for(bot_instance)
        }.to change(Message, :count).by(1)

        expect(Message.last.provider).to eq 'slack'
        expect(Message.last.team_id).to eq 'T1234'
      end

      it 'returns object' do
        expect(message.save_for(bot_instance)).to be_an_instance_of(Message)
      end

      context 'with notification' do
        let(:notification) { create(:notification) }

        it 'saves with notification' do
          message_object = message.save_for(bot_instance, notification: notification)

          expect(message_object.notification).to eq notification
        end
      end
    end

    context 'invalid' do
      let(:message) { Messages::Slack.new(team_id: nil, channel: 'C5678', text: 'OK!') }

      it 'does not save a message in the DB' do
        expect {
          message.save_for(bot_instance)
        }.to_not change(Message, :count)
      end

      it 'returns false' do
        expect(message.save_for(bot_instance)).to be_falsy
      end
    end
  end
end
