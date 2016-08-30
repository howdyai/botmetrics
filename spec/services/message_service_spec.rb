require 'rails_helper'

RSpec.describe MessageService do
  describe '#send_now' do
    context 'facebook' do
      context 'bot instance not enabled' do
        it 'returns false' do
          bot_instance = build_stubbed(:bot_instance, state: 'disabled', provider: 'facebook')
          message = build_stubbed(:message, :to_facebook, provider: 'facebook', bot_instance: bot_instance)

          result = MessageService.new(message).send_now

          expect(result).to be false
        end
      end

      context 'enabled instance and with channel' do
        it 'log response, update sent_at timestamp' do
          bot_instance = build_stubbed(:bot_instance, state: 'enabled', token: 'token', provider: 'facebook')
          message = build_stubbed(:message, :to_facebook, provider: 'facebook', bot_instance: bot_instance, notification: build_stubbed(:notification))

          service = double(call: { 'ok' => true })
          allow(PostMessageToFacebookService).to receive_message_chain(:new) { service }

          allow(PusherJob).to receive(:perform_async)
          allow(message).to receive(:log_response)
          allow(message).to receive(:update)

          result = MessageService.new(message).send_now

          expect(message).to have_received(:log_response)
          expect(message).to have_received(:update)
          expect(PusherJob).to have_received(:perform_async)
        end
      end
    end

    context 'slack' do
      context 'bot instance not enabled' do
        it 'returns false' do
          bot_instance = build_stubbed(:bot_instance, provider: 'slack', state: 'disabled')
          message = build_stubbed(:message, :to_user, provider: 'slack', bot_instance: bot_instance)

          result = MessageService.new(message).send_now

          expect(result).to be false
        end
      end

      context 'enabled instance but without channel' do
        before { allow(PostMessageToSlackService).to receive_message_chain(:new, :channel, nil) }

        it 'returns false' do
          bot_instance = build_stubbed(:bot_instance, provider: 'slack', state: 'enabled')
          message = build_stubbed(:message, :to_user, provider: 'slack', bot_instance: bot_instance)

          result = MessageService.new(message).send_now

          expect(result).to be false
        end
      end

      context 'enabled instance and with channel' do
        it 'log response, update sent_at timestamp' do
          bot_instance = build_stubbed(:bot_instance, provider: 'slack', state: 'enabled', token: 'token')
          message = build_stubbed(:message, provider: 'slack', bot_instance: bot_instance, notification: build_stubbed(:notification))

          service = double(channel: '1234', call: { 'ok' => true })
          allow(PostMessageToSlackService).to receive_message_chain(:new) { service }

          allow(PusherJob).to receive(:perform_async)
          allow(message).to receive(:log_response)
          allow(message).to receive(:update)

          result = MessageService.new(message).send_now

          expect(message).to have_received(:log_response)
          expect(message).to have_received(:update)
          expect(PusherJob).to have_received(:perform_async)
        end
      end
    end
  end
end
