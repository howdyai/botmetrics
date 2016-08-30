require 'rails_helper'

RSpec.describe Message do
  context 'associations' do
    it { is_expected.to belong_to :bot_instance }
    it { is_expected.to belong_to :notification }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :bot_instance }
  end

  describe '#duplicate_provider_from_bot_instance' do
    it 'copies provider' do
      message =
        Message.create(
          bot_instance: create(:bot_instance, provider: 'slack'),
          message_attributes: { team_id: 'T123', user: 'U123'}
        )

      expect(message.reload.provider).to eq 'slack'
    end
  end

  describe '#can_send_now?' do
    context 'on schedule' do
      context 'not sent yet' do
        it 'returns true' do
          message = build_stubbed(:message, scheduled_at: 3.minutes.ago, sent_at: nil)

          expect(message.can_send_now?).to be true
        end
      end

      context 'already sent' do
        it 'returns false' do
          message = build_stubbed(:message, scheduled_at: 3.minutes.ago, sent_at: 2.minutes.ago)

          expect(message.can_send_now?).to be false
        end
      end
    end

    context 'not on schedule' do
      it 'returns false' do
        message = build_stubbed(:message, scheduled_at: Time.zone.tomorrow)

        expect(message.can_send_now?).to be false
      end
    end
  end

  describe '#log_response' do
    context 'slack' do
      context 'success' do
        let(:response) { { 'ok' => true } }

        it 'log success, response and returns true' do
          message = build_stubbed(:message, provider: 'slack')

          expect(message).to receive(:update).with(
            success: true, response: response
          )

          result = message.log_response(response)
        end
      end

      context 'failure' do
        let(:response) { { 'ok' => false } }

        it 'log success, response and returns false' do
          message = build_stubbed(:message, provider: 'slack')

          expect(message).to receive(:update).with(
            success: false, response: response
          )

          result = message.log_response(response)
        end
      end
    end

    context 'facebook' do
      context 'success' do
        let(:response) { { 'recipient_id' => 'recipient_id', 'message_id' => 'message_id' } }

        it 'log success, response and returns true' do
          message = build_stubbed(:message, provider: 'facebook')

          expect(message).to receive(:update).with(
            success: true, response: response
          )

          result = message.log_response(response)
        end
      end

      context 'failure' do
        let(:response) { { 'error' => 'wrong' } }

        it 'log success, response and returns false' do
          message = build_stubbed(:message, provider: 'facebook')

          expect(message).to receive(:update).with(
            success: false, response: response
          )

          result = message.log_response(response)
        end
      end
    end
  end
end
