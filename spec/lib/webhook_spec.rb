RSpec.describe Webhook do
  describe '#.ping' do
    let(:bot) { create(:bot) }

    def do_request
      Webhook.ping bot.id
    end

    it 'set correct header' do
      allow(Excon).to receive(:post)

      do_request

      expect(Excon).to have_received(:post)
    end
  end
end
