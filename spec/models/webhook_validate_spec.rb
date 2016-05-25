RSpec.describe WebhookValidate do
  describe 'call' do
    context 'webhook is legit' do
      let(:bot) { create(:bot) }

      before do
        allow(Excon).to receive(:get) { double(status: 200) }
      end

      it 'invokes Pusher with correct arguments' do
        allow(PusherJob).to receive(:perform_async)

        expect { WebhookValidate.new(bot.id).call }.to change(bot.webhook_histories, :count).by(1)
        
        bot.webhook_histories.last.tap do |webhook_history|
          expect(webhook_history.code).to eq 200
        end

        expect(PusherJob).to have_received(:perform_async).
          with("webhook-validate-bot", "webhook-validate-bot-#{bot.id}", %<{"ok":true}>)
      end
    end

    context 'webhook is not legit' do
      let(:bot) { create(:bot) }

      before do
        allow(Excon).to receive(:get) { double(status: 500) }
      end

      it 'invokes Pusher with correct arguments' do
        allow(PusherJob).to receive(:perform_async)

        WebhookValidate.new(bot.id).call
        
        bot.webhook_histories.last.tap do |webhook_history|
          expect(webhook_history.code).to eq 500
        end

        expect(PusherJob).to have_received(:perform_async).
          with("webhook-validate-bot", "webhook-validate-bot-#{bot.id}", %<{"ok":false}>)
      end
    end
  end
end
