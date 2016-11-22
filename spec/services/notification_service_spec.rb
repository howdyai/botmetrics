require 'rails_helper'

RSpec.describe NotificationService do
  let(:service)      { NotificationService.new(notification) }

  let(:bot)          { create(:bot) }
  let(:bot_instance) { create(:bot_instance, :with_attributes, bot: bot) }
  let(:bot_user)     { create(:bot_user, :with_attributes, bot_instance: bot_instance) }

  before { allow(SendMessageJob).to receive(:perform_async) }

  let(:query_set)    { build(:query_set, :with_slack_queries, bot: bot) }

  before { allow(FilterBotUsersService).to receive_message_chain(:new, :scope) { BotUser.where(id: bot_user.id) } }

  describe '#send_now' do
    let(:notification) { create(:notification, query_set: query_set) }

    context 'slack' do
      context 'notification has messages' do
        let!(:message) { create(:message, :to_user, bot_instance: bot_instance, notification: notification) }

        it 'recreates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to_not change(notification.messages, :count)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          # Test that message was deleted and recreated
          new_message = notification.messages.last
          expect(new_message.id).to_not         eq message.id
          expect(notification.messages.count).to eq 1

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end

      context 'notification has no messages' do
        it 'creates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to eq bot_user.bot_instance.team_id
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end
    end

    context 'facebook' do
      let!(:bot)          { create(:bot, provider: 'facebook') }
      let!(:bot_instance) { create(:bot_instance, :with_attributes_facebook, bot: bot, provider: 'facebook') }

      let!(:bot_user)     { create(:bot_user, :with_facebook_attributes, bot_instance: bot_instance, provider: 'facebook') }
      let!(:query_set)    { build(:query_set, :with_facebook_queries, bot: bot) }

      context 'notification has messages' do
        let!(:message) { create(:message, :to_facebook, bot_instance: bot_instance, notification: notification) }

        it 'recreates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to_not change(notification.messages, :count)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          # Test that message was deleted and recreated
          new_message = notification.messages.last
          expect(new_message.id).to_not         eq message.id
          expect(new_message.provider).to       eq 'facebook'
          expect(notification.messages.count).to eq 1

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end

      context 'notification has no messages' do
        it 'creates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to be_blank
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content
          expect(message.provider).to eq 'facebook'

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end
    end

    context 'kik' do
      let!(:bot)          { create(:bot, provider: 'kik') }
      let!(:bot_instance) { create(:bot_instance, :with_attributes_kik, bot: bot, provider: 'kik') }

      let!(:bot_user)     { create(:bot_user, :with_kik_attributes, bot_instance: bot_instance, provider: 'kik') }
      let!(:query_set)    { build(:query_set, :with_kik_queries, bot: bot) }

      context 'notification has messages' do
        let!(:message) { create(:message, :to_kik, bot_instance: bot_instance, notification: notification) }

        it 'recreates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to_not change(notification.messages, :count)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          # Test that message was deleted and recreated
          new_message = notification.messages.last
          expect(new_message.id).to_not         eq message.id
          expect(new_message.provider).to       eq 'kik'
          expect(notification.messages.count).to eq 1

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end

      context 'notification has no messages' do
        it 'creates and sends messages' do
          expect {
            service.send_now
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to be_blank
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content
          expect(message.provider).to eq 'kik'

          expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        end
      end
    end
  end

  describe '#enqueue_messages' do
    let(:notification) { create(:notification, query_set: query_set, scheduled_at: 'May 25, 2016 8:00 PM') }

    context 'slack' do
      context 'notification has messages' do
        let!(:message) { create(:message, :to_user, bot_instance: bot_instance, notification: notification) }

        context "message hasn't been sent yet" do
          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not          eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message hasn't been sent yet (but is meant for the user returned by FilterBotUsersService)" do
          before { message.update_attributes(message_attributes: { user: bot_user.uid, team_id: 'T123' }) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(new_message.user).to eql       bot_user.uid
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already" do
          before { message.update_attribute(:sent_at, 2.days.ago) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to change(notification.messages, :count).by(1)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(notification.messages.count).to eq 2

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already to the user returned by FilterBotUsersService" do
          before { message.update_attributes(sent_at: 2.days.ago, message_attributes: { user: bot_user.uid, team_id: 'T123' }) }

          it "doesn't add any new messages" do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)
            new_message = notification.messages.last

            expect(new_message.id).to         eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end
      end

      context 'notification has no messages' do
        it 'creates and enqueues messages' do
          expect {
            service.enqueue_messages
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to eq bot_user.bot_instance.team_id
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content

          # with time zone information from bot_user
          expect(message.scheduled_at).to eq notification.scheduled_at.in_time_zone(bot_user.user_attributes['timezone']).utc

          expect(SendMessageJob).to_not have_received(:perform_async)
        end
      end
    end

    context 'facebook' do
      let!(:bot)          { create(:bot, provider: 'facebook') }
      let!(:bot_instance) { create(:bot_instance, :with_attributes_facebook, bot: bot, provider: 'facebook') }

      let!(:bot_user)     { create(:bot_user, :with_facebook_attributes, bot_instance: bot_instance, provider: 'facebook') }
      let!(:query_set)    { build(:query_set, :with_facebook_queries, bot: bot) }

      context 'notification has messages' do
        let!(:message) { create(:message, :to_facebook, bot_instance: bot_instance, notification: notification) }

        context "message hasn't been sent yet" do
          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not          eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message hasn't been sent yet (but is meant for the user returned by FilterBotUsersService)" do
          before { message.update_attributes(message_attributes: { user: bot_user.uid, team_id: 'T123' }) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(new_message.user).to eql       bot_user.uid
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already" do
          before { message.update_attribute(:sent_at, 2.days.ago) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to change(notification.messages, :count).by(1)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(notification.messages.count).to eq 2

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already to the user returned by FilterBotUsersService" do
          before { message.update_attributes(sent_at: 2.days.ago, message_attributes: { user: bot_user.uid, team_id: 'T123' }) }

          it "doesn't add any new messages" do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)
            new_message = notification.messages.last

            expect(new_message.id).to         eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end
      end

      context 'notification has no messages' do
        it 'creates and enqueues messages' do
          expect {
            service.enqueue_messages
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to eq bot_user.bot_instance.team_id
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content

          # with time zone information from bot_user
          expect(message.scheduled_at).to eq notification.scheduled_at.in_time_zone(bot_user.user_attributes['timezone']).utc

          expect(SendMessageJob).to_not have_received(:perform_async)
        end
      end
    end

    context 'kik' do
      let!(:bot)          { create(:bot, provider: 'kik') }
      let!(:bot_instance) { create(:bot_instance, :with_attributes_kik, bot: bot, provider: 'kik') }

      let!(:bot_user)     { create(:bot_user, :with_kik_attributes, bot_instance: bot_instance, provider: 'kik') }
      let!(:query_set)    { build(:query_set, :with_kik_queries, bot: bot) }

      context 'notification has messages' do
        let!(:message) { create(:message, :to_kik, bot_instance: bot_instance, notification: notification) }

        context "message hasn't been sent yet" do
          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not          eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message hasn't been sent yet (but is meant for the user returned by FilterBotUsersService)" do
          before { message.update_attributes(message_attributes: { user: bot_user.uid }) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(new_message.user).to eql       bot_user.uid
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already" do
          before { message.update_attribute(:sent_at, 2.days.ago) }

          it 'recreates and enqueues messages' do
            expect {
              service.enqueue_messages
              notification.reload
            }.to change(notification.messages, :count).by(1)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)

            # Test that message was deleted and recreated
            new_message = notification.messages.last
            expect(new_message.id).to_not         eq message.id
            expect(notification.messages.count).to eq 2

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end

        context "message has been sent already to the user returned by FilterBotUsersService" do
          before { message.update_attributes(sent_at: 2.days.ago, message_attributes: { user: bot_user.uid }) }

          it "doesn't add any new messages" do
            expect {
              service.enqueue_messages
              notification.reload
            }.to_not change(notification.messages, :count)

            expect(FilterBotUsersService).to have_received(:new).with(query_set)
            new_message = notification.messages.last

            expect(new_message.id).to         eq message.id
            expect(notification.messages.count).to eq 1

            expect(SendMessageJob).to_not have_received(:perform_async)
          end
        end
      end

      context 'notification has no messages' do
        it 'creates and enqueues messages' do
          expect {
            service.enqueue_messages
            notification.reload
          }.to change(notification.messages, :count).by(1)

          expect(FilterBotUsersService).to have_received(:new).with(query_set)

          message = notification.messages.last
          expect(message.team_id).to eq bot_user.bot_instance.team_id
          expect(message.user).to eq bot_user.uid
          expect(message.text).to eq notification.content

          # with timezone set as GMT (because Kik users don't have a timezone set)
          expect(message.scheduled_at).to eq notification.scheduled_at.in_time_zone('GMT').utc

          expect(SendMessageJob).to_not have_received(:perform_async)
        end
      end
    end
  end
end
