require 'spec_helper'

RSpec.describe SendMessageJob do
  describe '#perform' do
    let(:mocked_service) { double(:message_service).as_null_object }

    before do
      allow(MessageService).to receive(:new) { mocked_service }
      allow(mocked_service).to receive(:send_now) { true }
    end

    let(:message)  { create(:message, :to_user) }

    it 'sends message' do
      SendMessageJob.new.perform(message.id)

      expect(MessageService).to have_received(:new).with(message)
      expect(mocked_service).to have_received(:send_now)
    end

    context 'message belongs to a notification' do
      let(:notification) { create(:notification) }
      let(:message)      { create(:message, :to_user, notification: notification) }

      before { allow(PusherJob).to receive(:perform_async) }

      it 'invokes PusherJob' do
        SendMessageJob.new.perform(message.id)

        expect(PusherJob).to have_received(:perform_async).
          with(
            "notification",
            "notification-#{notification.id}",
            {
              ok: message.success,
              recipient: message.user,
              sent: notification.messages.sent.count
            }.to_json
        )
      end
    end
  end
end
