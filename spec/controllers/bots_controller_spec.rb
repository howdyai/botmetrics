RSpec.describe BotsController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot  }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

  describe 'GET new' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    def do_request
      get :new
    end

    it 'should render template :new' do
      do_request
      expect(response).to render_template :new
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Viewed New Bot Page', user.id)
    end
  end

  describe 'POST create' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    let!(:bot_params) { { name: 'My First Bot', webhook_url: 'https://example.com/bot_metrics' } }

    def do_request
      post :create, bot: bot_params
    end

    it 'should create a new bot' do
      expect {
        do_request
        user.reload
      }.to change(user.bots, :count).by(1)

      bot = user.bots.last
      expect(bot.name).to eql 'My First Bot'
      expect(bot.webhook_url).to eql 'https://example.com/bot_metrics'
      expect(bot.provider).to eql 'slack'
    end

    it 'should redirect to bot_path' do
      do_request
      bot = user.bots.last
      expect(response).to redirect_to bot_path(bot)
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Created Bot', user.id)
    end

    context 'with invalid params' do
      let!(:bot_params) { { name: '' } }

      it 'should NOT create a new bot' do
        expect {
          do_request
          user.reload
        }.to_not change(user.bots, :count)
      end

      it 'should render template :new' do
        do_request
        expect(response).to render_template :new
      end

      it 'should NOT track the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to_not have_received(:perform_async)
      end
    end
  end

  describe 'GET show' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    def do_request
      get :show, id: bot.to_param
    end

    context 'if there are no bot instances' do
      it 'should redirect to the new_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_bot_instance_path(bot)
      end

      it 'should NOT track the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to_not have_received(:perform_async)
      end
    end

    context 'if there are bot instances (that are pending)' do
      let!(:bi1) { create :bot_instance, bot: bot }

      it 'should redirect to the new_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_bot_instance_path(bot)
      end

      it 'should NOT track the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to_not have_received(:perform_async)
      end
    end

    context 'if there are bot instances (that are disabled)' do
      let!(:bi1) { create :bot_instance, bot: bot, state: 'disabled' }

      it 'should render template :show' do
        do_request
        expect(response).to render_template :show
      end

      it 'should track the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Viewed Bot Dashboard Page', user.id)
      end
    end
  end

  describe 'GET edit' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    def do_request
      get :edit, id: bot.to_param
    end

    it 'should render template :edit' do
      do_request
      expect(response).to render_template :edit
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Viewed Edit Bot Page', user.id)
    end
  end

  describe 'PATCH update' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    let!(:bot_params) { { name: 'Nestor Dev', webhook_url: 'https://example.com' } }

    def do_request
      patch :update, id: bot.to_param, bot: bot_params
    end

    it 'should update the name of the bot' do
      allow(WebhookValidateJob).to receive(:perform_async)

      expect {
        do_request
        bot.reload
      }.to change(bot, :name).to('Nestor Dev').and change(bot, :webhook_url).to('https://example.com')
    end

    it 'should redirect to bot_verifying_webhook_path' do
      allow(WebhookValidateJob).to receive(:perform_async)

      do_request

      expect(response).to redirect_to bot_verifying_webhook_path(bot)
    end

    it 'should track the event on Mixpanel' do
      expect(WebhookValidateJob).to receive(:perform_async)

      do_request

      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Updated Bot', user.id)
    end

    context 'without webhook url changes' do
      let!(:bot_params) { { name: 'test', webhook_url: "" } }

      it 'should redirect to bot_path' do
        expect(WebhookValidateJob).not_to receive(:perform_async)

        do_request

        expect(response).to redirect_to bot_path(bot)
      end
    end

    context 'without a valid name' do
      let!(:bot_params) { { name: '' } }

      it 'should NOT update the name of the bot' do
        expect {
          do_request
          bot.reload
        }.to_not change(bot, :name)
      end

      it 'should render template :edit' do
        do_request
        expect(response).to render_template :edit
      end

      it 'should NOT track the event on Mixpanel' do
        do_request
        expect(TrackMixpanelEventJob).to_not have_received(:perform_async)
      end
    end
  end

  describe 'GET webhook_events' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    def do_request
      get :webhook_events, id: bot.to_param
    end

    it 'success' do
      do_request
      expect(response).to be_success
    end
  end
end
