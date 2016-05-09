require 'rails_helper'

RSpec.describe SlackService do
  let(:user_message) { create(:message, :to_user) }
  let(:chan_message) { create(:message, :to_channel) }

  describe '#send_now' do
    let(:fake_slack) { spy(:slack) }

    before { allow(Slack).to receive(:new) { fake_slack } }

    context 'failures' do
      let(:bot_instance) { build(:bot_instance, state: bot_state) }

      context 'bot instance is not enabled' do
        let(:bot_state) { 'pending' }
        let(:message) { Message.new(bot_instance: bot_instance) }
        let(:service) { SlackService.new(message) }

        it { expect(service.send_now).to be_falsy }
      end

      context 'channel is blank' do
        let(:bot_state) { 'enabled' }
        let(:message) { Message.new(bot_instance: bot_instance, text: 'text')}
        let(:service) { SlackService.new(message) }

        it { expect(service.send_now).to be_falsy }
      end

      context 'text and attachments are blank' do
        let(:bot_state) { 'enabled' }
        let(:message) { Message.new(bot_instance: bot_instance, message_attributes: { channel: 'C123' })}
        let(:service) { SlackService.new(message) }

        it { expect(service.send_now).to be_falsy }
      end
    end

    context 'user message' do
      let(:service) { SlackService.new(user_message) }

      it 'works' do
        expect(fake_slack).to receive(:call).
          with(
            'im.open',
            'POST',
            user: user_message.user
          ).
          and_return(
            { 'ok' => true, 'channel' => { 'id' => '123' } }
          )

        expect(fake_slack).to receive(:call).
          with(
            'chat.postMessage',
            'POST',
            { channel: '123', text: user_message.text }
          )

        service.send_now
      end
    end

    context 'channel message' do
      let(:service) { SlackService.new(chan_message) }

      it 'works' do
        expect(fake_slack).to receive(:call).
          with(
            'chat.postMessage',
            'POST',
            { channel: chan_message.channel, text: chan_message.text }
          )

        service.send_now
      end
    end
  end
end
