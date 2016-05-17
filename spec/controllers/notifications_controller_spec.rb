require 'rails_helper'

RSpec.describe NotificationsController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc)   { create :bot_collaborator, bot: bot, user: user }

  before { sign_in user }

  def dt_fmt(dt)
    dt.strftime('%b %d, %Y %l:%M %p')
  end

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
      before do
        allow(SendNotificationJob).to receive(:perform_async)
        allow(EnqueueNotificationJob).to receive(:perform_async)
        allow(TrackMixpanelEventJob).to receive(:perform_async)
      end

      context 'send now' do
        let(:params) { { notification: { content: 'Hello World', bot_user_ids: ['1', '2'] } } }

        it 'queues up a job' do
          do_request

          expect(SendNotificationJob).to have_received(:perform_async).with(Notification.last.id)
        end

        it 'saves and redirects' do
          expect_any_instance_of(Notification).to receive(:save).with(context: :schedule).and_call_original

          expect {
            do_request
          }.to change(Notification, :count).by(1)

          expect(Notification.last.bot_user_ids).to eq ['1', '2']

          expect(response).to redirect_to bot_notification_path(bot, Notification.last)
        end

        it 'tracks the event on Mixpanel' do
          do_request

          expect(TrackMixpanelEventJob).to have_received(:perform_async).with 'Created Notification', user.id, bot_users: 2
        end
      end

      context 'send at a specific time' do
        let(:params) do
          { notification:
              {
                content: 'Hello World',
                bot_user_ids: ['1', '2'],
                scheduled_at: scheduled_at
              }
          }
        end
        let(:scheduled_at) { dt_fmt 5.days.from_now }

        it 'queues up a job' do
          do_request

          expect(EnqueueNotificationJob).to have_received(:perform_async)
        end

        it 'saves and redirects' do
          expect {
            do_request
          }.to change(Notification, :count).by(1)

          expect(Notification.last.bot_user_ids).to eq ['1', '2']
          expect(Notification.last.scheduled_at).to eq scheduled_at

          expect(response).to redirect_to bot_notifications_path(bot)
        end
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
    let!(:notification) { create(:notification, bot: bot) }

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

  describe '#edit' do
    let!(:notification) { create(:notification, bot: bot, scheduled_at: scheduled_at) }

    def do_request
      get :edit, bot_id: bot.uid, id: notification.id
    end

    context 'sent immediately' do
      let(:scheduled_at) { nil }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and sent' do
      let(:scheduled_at) { dt_fmt 5.days.ago }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and not sent' do
      let(:scheduled_at) { dt_fmt 5.days.from_now }

      it 'works' do
        do_request

        expect(response).to be_success
      end
    end
  end

  describe '#update' do
    let!(:notification) { create(:notification, bot: bot, scheduled_at: scheduled_at) }

    def do_request
      patch :update, { bot_id: bot.uid, id: notification.id }.merge(params)
    end

    context 'sent immediately' do
      let(:params) { { notification: { content: 'New' } } }
      let(:scheduled_at) { nil }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and sent' do
      let(:params) { { notification: { content: 'New' } } }
      let(:scheduled_at) { dt_fmt 5.days.ago }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and not sent' do
      let(:scheduled_at) { dt_fmt 5.days.from_now }

      context 'success' do
        before do
          allow(SendNotificationJob).to receive(:perform_async)
          allow(EnqueueNotificationJob).to receive(:perform_async)
        end

        context 'send now' do
          let(:params) { { notification: { content: 'New', scheduled_at: '' } } }

          it 'queues up a job' do
            do_request

            expect(SendNotificationJob).to have_received(:perform_async).with(Notification.last.id)
          end

          it 'saves and redirects' do
            expect_any_instance_of(Notification).to receive(:save).with(context: :schedule).and_call_original

            do_request

            expect(Notification.last.content).to eq 'New'

            expect(response).to redirect_to bot_notification_path(bot, Notification.last)
          end
        end

        context 'send at a specific time' do
          let(:params) do
            { notification:
                {
                  content: 'New',
                  scheduled_at: new_scheduled_at
                }
            }
          end
          let(:new_scheduled_at) { dt_fmt 10.days.from_now }

          it 'queues up a job' do
            do_request

            expect(EnqueueNotificationJob).to have_received(:perform_async)
          end

          it 'saves and redirects' do
            do_request

            expect(Notification.last.content).to eq 'New'
            expect(Notification.last.scheduled_at).to eq new_scheduled_at

            expect(response).to redirect_to bot_notifications_path(bot)
          end
        end
      end

      context 'failure' do
        let(:params) { { notification: { content: '' } } }

        it 'does not queue up a job' do
          do_request

          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe '#destroy' do
    let!(:notification) { create(:notification, bot: bot, scheduled_at: scheduled_at) }

    def do_request
      delete :destroy, bot_id: bot.uid, id: notification.id
    end

    context 'sent immediately' do
      let(:scheduled_at) { nil }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and sent' do
      let(:scheduled_at) { dt_fmt 5.days.ago }

      it 'raises error' do
        do_request

        expect(response.status).to eq 404
      end
    end

    context 'scheduled and not sent' do
      let(:scheduled_at) { dt_fmt 5.days.from_now }

      it 'works' do
        expect {
          do_request
        }.to change(Notification, :count).by(-1)

        expect(response).to redirect_to bot_notifications_path(bot)
      end
    end
  end
end
