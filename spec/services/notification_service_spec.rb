require 'rails_helper'

RSpec.describe NotificationService do
  describe '#send_now' do
    let(:service)      { NotificationService.new(notification) }

    let(:notification) { create(:notification, bot_user_ids: [bot_user.id]) }
    let(:bot_instance) { create(:bot_instance, instance_attributes: { team_id: 'T123' }) }
    let(:bot_user)     { create(:bot_user, bot_instance: bot_instance) }

    before { allow(SendMessageJob).to receive(:perform_async) }

    it 'creates and sends messages' do
      expect {
        service.send_now
      }.to change(Message, :count).by(1)

      expect(SendMessageJob).to have_received(:perform_async).with(Notification.last.id)

      message = Message.last
      expect(message.team_id).to eq bot_user.bot_instance.team_id
      expect(message.user).to eq bot_user.uid
      expect(message.text).to eq notification.content
    end
  end
end
