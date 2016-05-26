RSpec.describe Webhook do
  describe '.ping' do
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

  describe '.deliver' do
    let(:bot) { create(:bot) }
    let(:event) { create(:event) }

    def do_request
      Webhook.deliver bot.id, event
    end

    it 'set correct header' do
      allow(Excon).to receive(:post) { double(status: 200) }

      do_request

      expect(Excon).to have_received(:post)
      bot.webhook_events.last.tap do |webhook_event|
        expect(webhook_event.code).to eq 200
        expect(webhook_event.elapsed_time.to_f).to be > 0
      end
    end
  end
end
