require 'rails_helper'

RSpec.describe NotificationsController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc)   { create :bot_collaborator, bot: bot, user: user }

  before { sign_in user }

  describe '#index' do
    def do_request
      get :index, bot_id: bot.uid
    end

    context 'with notifications' do
      before do
        create(:notification, bot: bot)
        allow(TrackMixpanelEventJob).to receive(:perform_async)
      end

      it 'works' do
        do_request

        expect(response).to be_success
      end

      it 'tracks the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Viewed Notifications Index Page', user.id)
      end
    end

    context 'with no notifications' do
      it 'works' do
        do_request

        expect(response).to redirect_to new_bot_notification_path(bot)
      end
    end
  end

  describe '#new' do
    before { allow(TrackMixpanelEventJob).to receive(:perform_async) }

    def do_request
      get :new, bot_id: bot.uid
    end

    it 'works' do
      do_request

      expect(response).to be_success
    end

    it 'tracks the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Viewed New Notification Page', user.id)
    end
  end

  describe '#create' do
    def do_request
      post :create, { bot_id: bot.uid }.merge(params)
    end

    context 'success' do
      let(:params) { { notification: { content: 'Hello World', bot_user_ids: ['1', '2'] } } }

      before do
        allow(SendNotificationJob).to receive(:perform_async)
        allow(TrackMixpanelEventJob).to receive(:perform_async)
      end

      it 'queues up a job' do
        do_request
        notification = bot.notifications.last
        expect(SendNotificationJob).to have_received(:perform_async).with(notification.id)
      end

      it 'saves and redirects' do
        expect {
          do_request
          bot.reload
        }.to change(bot.notifications, :count).by(1)

        notification = bot.notifications.last
        expect(notification.bot_user_ids).to eq ['1', '2']
        expect(response).to redirect_to bot_notification_path(bot, notification)
      end

      it 'tracks the event on Mixpanel' do
        do_request
        notification = bot.notifications.last

        expect(TrackMixpanelEventJob).to have_received(:perform_async).with 'Created Notification', user.id, bot_users: 2
      end
    end

    context 'failure' do
      let(:params) { { notification: { content: '' } } }

      it 'does not queue up a job' do
        do_request

        expect(response).to render_template(:new)
      end
    end
  end

  describe '#show' do
    let!(:notification) { create(:notification) }

    before { allow(TrackMixpanelEventJob).to receive(:perform_async) }

    def do_request
      get :show, bot_id: bot.uid, id: notification.id
    end

    it 'works' do
      do_request

      expect(response).to be_success
    end

    it 'tracks the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with 'Viewed Notifications Show Page', user.id
    end
  end
end
