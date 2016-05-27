RSpec.describe Webhook do
  describe '#ping' do
    let(:bot) { create(:bot) }

    def do_request
      Webhook.new(bot.id).ping
    end

    it 'set correct header' do
      allow(Excon).to receive(:post)

      do_request

      expect(Excon).to have_received(:post)
    end
  end

  describe '#deliver' do
    let(:bot) { create(:bot) }
    let(:event) { create(:event) }

    def do_request
      Webhook.new(bot.id, event).deliver
    end

    it 'set correct header and update webhook event' do
      allow(Excon).to receive(:post) { double(status: 200) }
      allow(Stopwatch).to receive(:record) { |&block| block.call; 1 }

      do_request

      expect(Excon).to have_received(:post)
      bot.webhook_events.last.tap do |webhook_event|
        expect(webhook_event.code).to eq 200
        expect(webhook_event.elapsed_time.to_f).to be > 0
      end
    end
  end
end
