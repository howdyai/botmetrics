RSpec.describe PostMessageToFacebookService do
  describe '#call' do
    let(:message)         { build_stubbed(:message, :to_facebook, message_attributes: { user: 'cafedead' }, provider: 'facebook', text: 'test') }
    let(:facebook_client) { double(call: response) }
    let(:service)         { described_class.new(message, 'token') }

    before do
      allow(facebook_client).to receive(:call).with(
        'me/messages',
        'POST',
        {
          recipient: { id: 'cafedead' },
          message: { text: 'test' }
        }
      ).and_return(response)
      allow(Facebook).to receive(:new) { facebook_client }
    end

    context 'success' do
      let(:response) do
        {
          'recipient_id' => 'deadbeef',
          'message_id'   => 'message-id'
        }
      end

      it 'invokes Facebook client' do
        result = service.call
        expect(result).to eq response
      end
    end

    context 'failed' do
      let(:response) do
        {
          'error' => 'wrong'
        }
      end

      it 'invokes Facebook client' do
        result = service.call
        expect(result).to eq response
      end
    end
  end
end

