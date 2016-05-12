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
      before { create(:notification, bot: bot) }

      it 'works' do
        do_request

        expect(response).to be_success
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
    def do_request
      get :new, bot_id: bot.uid
    end

    it 'works' do
      do_request

      expect(response).to be_success
    end
  end

  describe '#create' do
    def do_request
      post :create, { bot_id: bot.uid }.merge(params)
    end

    context 'success' do
      let(:params) { { notification: { content: 'Hello World', bot_user_ids: ['1', '2'] } } }

      before { allow(SendNotificationJob).to receive(:perform_async) }

      it 'queues up a job' do
        do_request

        expect(SendNotificationJob).to have_received(:perform_async).with(Notification.last.id)
      end

      it 'saves and redirects' do
        expect {
          do_request
        }.to change(Notification, :count).by(1)

        expect(Notification.last.bot_user_ids).to eq ['1', '2']
        expect(response).to redirect_to bot_notification_path(bot, Notification.last)
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

    def do_request
      get :show, bot_id: bot.uid, id: notification.id
    end

    it 'works' do
      do_request

      expect(response).to be_success
    end
  end
end
