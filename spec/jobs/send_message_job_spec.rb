require 'spec_helper'

RSpec.describe SendMessageJob do
  describe '#perform' do
    it 'sends message' do
      message = build_stubbed('message')
      allow(Message).to receive(:find) { message }
      allow(MessageService).to receive_message_chain(:new, :send_now) { true }

      SendMessageJob.new.perform(message.id)

      expect(MessageService).to have_received(:new)
    end
  end
end
