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
    let(:relax_event) do
      {
        type: 'message_new',
        user_uid: 'user_uid',
        channel_uid: SecureRandom.hex(4),
        team_uid: 'team_uid',
        im: true,
        text: 'hello world',
        relax_bot_uid: 'URELAXBOT',
        timestamp: Time.at(rand * Time.now.to_i).to_i,
        provider: bot.provider,
        event_timestamp: Time.at(rand * Time.now.to_i).to_i,
      }
    end

    def do_request
      Webhook.new(bot.id, relax_event.to_json).deliver
    end

    it 'set correct header and update webhook event' do
      allow(Excon).to receive(:post) { double(status: 200) }
      allow(Stopwatch).to receive(:record) { |&block| block.call; 1 }

      do_request

      expect(Excon).to have_received(:post)
      bot.webhook_events.last.tap do |webhook_event|
        expect(webhook_event.code).to eq 200
        expect(webhook_event.elapsed_time.to_f).to be > 0
        expect(webhook_event.payload['channel_uid']).to eql relax_event[:channel_uid]
        expect(webhook_event.payload['timestamp']).to eql relax_event[:timestamp]
      end
    end
  end
end
