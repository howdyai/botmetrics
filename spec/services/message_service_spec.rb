require 'rails_helper'

RSpec.describe MessageService do
  describe '#send_now' do
    context 'bot instance not enabled' do
      it 'returns false' do
        allow(Message).to receive_message_chain(:find, :bot_instance) { double(state: 'disabled') }

        result = MessageService.new(42).send_now

        expect(result).to be false
      end
    end

    context 'enabled instance but without channel' do
      it 'returns false' do
        allow(Message).to receive_message_chain(:find, :bot_instance) { double(state: 'enabled', token: 'token') }
        allow(PostMessageToSlackService).to receive_message_chain(:new, :channel) { nil }

        result = MessageService.new(42).send_now

        expect(result).to be false
      end
    end

    context 'enabled instance and with channel' do
      it 'log response, update sent_at timestamp' do
        bot_instance = build_stubbed(:bot_instance, state: 'enabled', token: 'token')
        message = build_stubbed(:message, bot_instance: bot_instance, notification: build_stubbed(:notification))
        expect(Message).to receive(:find) { message }

        response = double(channel: '1234', call: { 'ok' => true })
        allow(PostMessageToSlackService).to receive_message_chain(:new) { response }

        allow(message).to receive(:log_response)
        allow(message).to receive(:update)
        allow(message).to receive(:ping_pusher_for_notification)

        result = MessageService.new(42).send_now

        expect(message).to have_received(:log_response)
        expect(message).to have_received(:update)
        expect(message).to have_received(:ping_pusher_for_notification)
      end
    end
  end
end
