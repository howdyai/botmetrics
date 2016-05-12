require 'rails_helper'

RSpec.describe MessageService do
  let(:user_message) { create(:message, :to_user) }
  let(:chan_message) { create(:message, :to_channel) }

  describe '#send_now' do
    let(:fake_slack) { spy(:slack) }

    let(:success) do
      {
        'ok' => true, 'channel' => '123', 'ts' => '456',
        'message' => { 'type' => 'message', 'user' => 'U123', 'text' => 'OK!', 'bot_id' => 'B123', 'ts' => '123' }
      }
    end

    let(:failure) do
      {
        'ok' => false, 'error' => 'wrong'
      }
    end

    def expect_slack_find_user(user, response)
      expect(fake_slack).to receive(:call).
        with(
          'im.open',
          'POST',
          user: user
        ).
        and_return(
          response
        )
    end

    def expect_slack_send_message(channel, text, response)
      expect(fake_slack).to receive(:call).
        with(
          'chat.postMessage',
          'POST',
          { as_user: 'true', channel: channel, text: text }
        ).and_return(
          response
        )
    end

    before { allow(Slack).to receive(:new) { fake_slack } }

    context 'failures' do
      let(:bot_instance) { build(:bot_instance, state: bot_state) }

      context 'bot instance is not enabled' do
        let(:bot_state) { 'pending' }
        let(:message) { create(:message, :to_user, bot_instance: bot_instance) }
        let(:service) { MessageService.new(message) }

        it { expect(service.send_now).to be_falsy }
      end
    end

    context 'user message' do
      let(:service) { MessageService.new(user_message) }

      it 'works' do
        expect_slack_find_user(user_message.user, { 'ok' => true, 'channel' => { 'id' => '123' } })
        expect_slack_send_message('123', user_message.text, success)

        service.send_now

        expect(user_message.sent).to be_truthy
        expect(user_message.success).to be_truthy
        expect(user_message.response).to match(success)
      end

      it 'fails to find user' do
        expect_slack_find_user(user_message.user, { 'ok' => false, 'error' => 'user_not_found' })

        service.send_now

        expect(user_message.sent).to be_truthy
        expect(user_message.success).to be_falsy
        expect(user_message.response).to eq({ 'ok' => false, 'error' => 'user_not_found' })
      end

      it 'fails to send' do
        expect_slack_find_user(user_message.user, { 'ok' => true, 'channel' => { 'id' => '123' } })
        expect_slack_send_message('123', user_message.text, failure)

        service.send_now

        expect(user_message.sent).to be_truthy
        expect(user_message.success).to be_falsy
        expect(user_message.response).to eq(failure)
      end
    end

    context 'channel message' do
      let(:service) { MessageService.new(chan_message) }

      it 'works' do
        expect_slack_send_message(chan_message.channel, chan_message.text, success)

        service.send_now

        expect(chan_message.sent).to be_truthy
        expect(chan_message.success).to be_truthy
        expect(chan_message.response).to eq(success)
      end

      it 'fails to send' do
        expect_slack_send_message(chan_message.channel, chan_message.text, failure)

        service.send_now

        expect(chan_message.sent).to be_truthy
        expect(chan_message.success).to be_falsy
        expect(chan_message.response).to eq(failure)
      end
    end
  end
end
