require 'rails_helper'

RSpec.describe NotificationService do
  let(:service)      { NotificationService.new(notification) }

  let(:bot_instance) { create(:bot_instance, :with_attributes) }
  let(:bot_user)     { create(:bot_user, :with_attributes, bot_instance: bot_instance) }

  before { allow(SendMessageJob).to receive(:perform_async) }

  describe '#send_now' do
    let(:notification) { create(:notification, bot_user_ids: [bot_user.id]) }

    context 'notification has messages' do
      let!(:message) { create(:message, :to_user, bot_instance: bot_instance, notification: notification) }

      it 'recreates and sends messages' do
        expect {
          service.send_now
        }.to_not change(Message, :count)

        # Test that message was deleted and recreated
        expect(Message.last.id).to_not         eq message.id
        expect(notification.messages.count).to eq 1

        expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
      end
    end

    context 'notification has no messages' do
      it 'creates and sends messages' do
        expect {
          service.send_now
        }.to change(Message, :count).by(1)

        message = Message.last
        expect(message.team_id).to eq bot_user.bot_instance.team_id
        expect(message.user).to eq bot_user.uid
        expect(message.text).to eq notification.content

        expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
      end
    end
  end

  describe '#enqueue_messages' do
    let(:notification) { create(:notification, bot_user_ids: [bot_user.id], scheduled_at: 'May 25, 2016 8:00 PM') }

    context 'notification has messages' do
      let!(:message) { create(:message, :to_user, bot_instance: bot_instance, notification: notification) }

      it 'recreates and enqueues messages' do
        expect {
          service.enqueue_messages
        }.to_not change(Message, :count)

        # Test that message was deleted and recreated
        expect(Message.last.id).to_not         eq message.id
        expect(notification.messages.count).to eq 1

        expect(SendMessageJob).to_not have_received(:perform_async)
      end
    end

    context 'notification has no messages' do
      it 'creates and enqueues messages' do
        expect {
          service.enqueue_messages
        }.to change(Message, :count).by(1)

        message = Message.last
        expect(message.team_id).to eq bot_user.bot_instance.team_id
        expect(message.user).to eq bot_user.uid
        expect(message.text).to eq notification.content

        # with time zone information from bot_user
        expect(message.scheduled_at).to eq notification.scheduled_at.in_time_zone(bot_user.user_attributes['timezone']).utc

        expect(SendMessageJob).to_not have_received(:perform_async)
      end
    end
  end
end
