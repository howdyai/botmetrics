require 'spec_helper'

RSpec.describe SendMessageJob do
  describe '#perform' do
    it 'sends message' do
      expect(MessageService).to receive_message_chain(:new, :send_now) { true }

      SendMessageJob.new.perform(42)
    end
  end
end
