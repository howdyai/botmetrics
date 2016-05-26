RSpec.describe WebhookValidate do
  describe 'call' do
    context 'webhook is legit' do
      let(:bot) { create(:bot) }

      before do
        allow(Webhook).to receive(:ping) { double(status: 200) }
      end

      it 'updates webhook status to true and invoke Pusher with correct args' do
        allow(PusherJob).to receive(:perform_async)

        WebhookValidate.new(bot.id).call
        expect(bot.reload.webhook_status).to be true
        expect(PusherJob).to have_received(:perform_async).
          with("webhook-validate-bot", "webhook-validate-bot-#{bot.id}", %<{"ok":true}>)
      end
    end

    context 'webhook is not legit' do
      let(:bot) { create(:bot) }

      before do
        allow(Webhook).to receive(:ping) { double(status: 500) }
      end

      it 'updates webhook status to false and invoke Pusher with correct args' do
        allow(PusherJob).to receive(:perform_async)

        WebhookValidate.new(bot.id).call
        expect(bot.reload.webhook_status).to be false
        expect(PusherJob).to have_received(:perform_async).
          with("webhook-validate-bot", "webhook-validate-bot-#{bot.id}", %<{"ok":false}>)
      end
    end
  end
end
