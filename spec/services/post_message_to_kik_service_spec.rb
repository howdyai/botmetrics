RSpec.describe PostMessageToKikService do
  describe '#call' do
    let(:message)    { build_stubbed(:message, :to_kik, message_attributes: { user: 'cafedead' }, provider: 'kik', text: 'test') }
    let(:kik_client) { double(call: response) }
    let(:service)    { described_class.new(message, 'token', 'kik-bot') }

    before do
      allow(kik_client).to receive(:call).with(
        'message',
        'POST',
        {
          messages: [{
            body: 'test',
            to: 'cafedead',
            type: 'text'
          }]
        }
      ).and_return(response)
      allow(Kik).to receive(:new) { kik_client }
    end

    context 'success' do
      let(:response) do
        {
          'status' => 200
        }
      end

      it 'invokes Kik client' do
        result = service.call
        expect(result).to eq response
      end
    end

    context 'failed' do
      let(:response) do
        {
          'status' => 400
        }
      end

      it 'invokes Kik client' do
        result = service.call
        expect(result).to eq response
      end
    end
  end
end
