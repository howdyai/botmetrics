RSpec.describe PostMessageToSlackService do
  describe '#channel' do
    context 'without message user' do
      it 'returns Message#channel' do
        message = build_stubbed(:message, message_attributes: Hash('channel': 'test'))

        result = described_class.new(message, 'token').channel

        expect(result).to eq 'test'
      end
    end

    context 'with message user and open channel' do
      let(:im_response) { Hash('ok' => true, 'channel' => { 'id' => '1234567' }) }

      before { allow(Slack).to receive(:new) { double(call: im_response) } }

      it 'query slack for open channel on behalf of user' do
        message = build_stubbed(:message, message_attributes: Hash('user': build_stubbed(:user)))

        result = described_class.new(message, 'token').channel

        expect(result).to eq '1234567'
      end
    end

    context 'without channel' do
      let(:im_response) { Hash('ok' => false) }

      before { allow(Slack).to receive(:new) { double(call: im_response) } }

      it 'invokes message log_response and returns false' do
        message = build_stubbed(:message, message_attributes: Hash('user': build_stubbed(:user)))

        expect(message).to receive(:log_response).with(im_response) { false }

        result = described_class.new(message, 'token').channel

        expect(result).to eq false
      end
    end
  end

  describe '#call' do
    let(:message) { build_stubbed(:message, text: 'test', attachments: ['attachment']) }
    let(:slack_client) { double(call: response) }
    let(:service) { described_class.new(message, 'token') }

    before do
      allow(slack_client).to receive(:call).with(
        'chat.postMessage',
        'POST',
        {
          as_user: 'true',
          channel: service.channel,
          text: message.text,
          attachments: message.attachments,
          mrkdwn: true,
        }
      )
    end

    context 'success' do
      let(:response) do
        {
          'ok' => true, 'channel' => '123', 'ts' => '456',
          'message' => {
            'type' => 'message', 'user' => 'U123',
            'text' => 'OK!', 'bot_id' => 'B123',
            'ts' => '123'
          }
        }
      end

      it 'invokes slack client' do
        allow(Slack).to receive(:new) { slack_client }

        result = service.call

        expect(result).to eq response
      end
    end

    context 'failed' do
      let(:response) do
        {
          'ok' => false, 'error' => 'wrong'
        }
      end

      it 'invokes slack client' do
        allow(Slack).to receive(:new) { slack_client }

        result = service.call

        expect(result).to eq response
      end
    end
  end
end
