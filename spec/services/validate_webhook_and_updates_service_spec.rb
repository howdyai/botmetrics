RSpec.describe ValidateWebhookAndUpdatesService do
  describe '#call' do
    let(:bot) { create(:bot) }

    def perform_work
      described_class.new(bot.id).call
    end

    before do
      allow(Webhook).to receive_message_chain(:new, :validate) { true }
    end

    it 'update webhook status and invoke Pusher to update UI' do
      expect(bot.webhook_status).to eq false
      allow(PusherJob).to receive(:perform_async)

      perform_work

      expect(bot.reload.webhook_status).to eq true
      expect(PusherJob).to have_received(:perform_async)
    end
  end
end
