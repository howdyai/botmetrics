RSpec.describe NewNotificationController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc)   { create :bot_collaborator, bot: bot, user: user }

  before { sign_in user }

  def dt_fmt(dt)
    dt.strftime('%b %d, %Y %l:%M %p')
  end

  before { allow(TrackMixpanelEventJob).to receive(:perform_async) }

  describe '#step_1' do
    def do_request
      get :step_1, { bot_id: bot.to_param }.merge(params)
    end

    context 'without params' do
      let(:params) { {} }

      it 'success' do
        do_request

        expect(response).to be_success
        expect(TrackMixpanelEventJob).to have_received(:perform_async)
      end
    end

    context 'with params' do
      let(:params) { { query_set: queries_attributes } }
      let(:queries_attributes) { { queries_attributes: { '0' => { provider: 'slack', field: 'nickname', method: 'equals_to', value: 'john' } } } }

      it 'success' do
        do_request

        expect(response).to be_success
        expect(TrackMixpanelEventJob).to have_received(:perform_async)
      end

      it 'sets session' do
        do_request

        expect(response).to be_success
        expect(session[:new_notification_query_set]).to match({query_set: hash_including})
        expect(session[:new_notification_query_set][:query_set][:queries_attributes].values.first).
          to match(hash_including(value: 'john'))
      end
    end

    context 'reset' do
      let(:params) { { reset: :reset } }

      before { session[:new_notification_query_set] = double('ok') }

      it 'resets session to default query' do
        do_request

        expect(session[:new_notification_query_set]).to match({query_set: hash_including})
      end
    end
  end

  describe '#step_2' do
    let(:params) { {} }

    def do_request
      get :step_2, { bot_id: bot.to_param }.merge(params)
    end

    context 'valid step 1' do
      before { session[:new_notification_query_set] = double(:ok) }
      after  { session[:new_notification_query_set] = nil }

      it 'works' do
        do_request

        expect(response).to be_success
        expect(TrackMixpanelEventJob).to have_received(:perform_async)
      end
    end

    context 'invalid step 1' do
      before { session[:new_notification_query_set] = nil }

      it 'redirects' do
        do_request

        expect(response).to redirect_to step_1_bot_new_notification_index_path(bot)
      end
    end
  end

  describe '#step_3' do
    def do_request
      get :step_3, { bot_id: bot.to_param }.merge(params)
    end

    context 'valid step 2' do
      let(:params) { { notification: { content: 'hello' } } }

      it 'works' do
        do_request

        expect(response).to be_success
        expect(TrackMixpanelEventJob).to have_received(:perform_async)
      end
    end

    context 'invalid step 2' do
      let(:params) { { notification: { content: '' } } }

      it 'redirects back to step 2' do
        do_request

        expect(response).to redirect_to step_2_bot_new_notification_index_path(bot, params.slice(:notification))
      end
    end
  end

  describe '#create' do
    let(:query_set) { { query_set: query_set_attributes.merge(queries_attributes) } }
    let(:query_set_attributes) { { bot_id: bot.id, instances_scope: 'enabled', time_zone: user.timezone } }
    let(:queries_attributes)   { { queries_attributes: { '0' => { provider: 'slack', field: 'nickname', method: 'equals_to', value: 'john' } } } }

    def do_request
      post :create, { bot_id: bot.to_param }.merge(params)
    end

    before { session[:new_notification_query_set] = query_set }

    context 'success' do
      before do
        allow(SendNotificationJob).to    receive(:perform_async)
        allow(EnqueueNotificationJob).to receive(:perform_async)
        allow(TrackMixpanelEventJob).to  receive(:perform_async)
      end

      context 'send now' do
        let(:params) { { notification: { content: 'Hello World', recurring: 'false' } } }

        it 'queues up a job' do
          do_request

          expect(SendNotificationJob).to have_received(:perform_async).with(Notification.last.id)
        end

        it 'saves and redirects' do
          expect { do_request }.
            to change(Notification, :count).by(1).
            and change(QuerySet, :count).by(1)

          expect(Notification.last.recurring).to be_falsey
          expect(response).to redirect_to bot_notification_path(bot, Notification.last)
          expect(TrackMixpanelEventJob).to have_received(:perform_async)
        end

        it 'clears the session' do
          do_request

          expect(session[:new_notification_query_set]).to be_nil
        end
      end

      context 'send at a specific time' do
        let(:params) do
          { notification:
              {
                content: 'Hello World',
                scheduled_at: scheduled_at,
                recurring: 'false'
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

          notification = Notification.last
          expect(notification.scheduled_at).to eq scheduled_at
          expect(notification.recurring).to be_falsey

          expect(response).to redirect_to bot_notifications_path(bot)
          expect(TrackMixpanelEventJob).to have_received(:perform_async)
        end

        it 'clears the session' do
          do_request

          expect(session[:new_notification_query_set]).to be_nil
        end
      end

      context 'send at a specific time (recurring)' do
        let(:params) do
          { notification:
              {
                content: 'Hello World',
                scheduled_at: scheduled_at,
                recurring: 'true'
              }
          }
        end
        let(:scheduled_at) { '9:00AM' }

        it 'queues up a job' do
          do_request

          expect(EnqueueNotificationJob).to_not have_received(:perform_async)
        end

        it 'saves and redirects' do
          expect {
            do_request
          }.to change(Notification, :count).by(1)

          notification = Notification.last

          expect(notification.scheduled_at).to eq scheduled_at
          expect(notification.recurring).to be_truthy

          expect(response).to redirect_to bot_notifications_path(bot)
          expect(TrackMixpanelEventJob).to have_received(:perform_async)
        end

        it 'clears the session' do
          do_request

          expect(session[:new_notification_query_set]).to be_nil
        end
      end
    end

    context 'failure' do
      context 'no content' do
        let(:params) { { notification: { content: '' } } }

        it 'does not queue up a job' do
          do_request
          expect(response).to redirect_to step_3_bot_new_notification_index_path(bot, params.slice(:notification))
        end
      end

      context 'invalid recurring scheduled_at' do
        let(:params) { { notification: { content: 'abc', scheduled_at: '13:00', recurring: true } } }

        it 'does not queue up a job' do
          do_request
          expect(response).to redirect_to step_3_bot_new_notification_index_path(bot, params.slice(:notification))
        end
      end
    end
  end
end
