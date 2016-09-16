RSpec.describe BotsController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot  }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

  describe 'GET new' do
    before do
      sign_in user
    end

    def do_request
      get :new
    end

    it 'should render template :new' do
      do_request
      expect(response).to render_template :new
    end
  end

  describe 'POST create' do
    before do
      sign_in user
    end

    let!(:bot_params) { { name: 'My First Bot', provider: 'facebook', webhook_url: 'https://example.com/bot_metrics' } }

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
      expect(bot.provider).to eql 'facebook'
    end

    it 'should set confirmed_at for the bot collaborator model created' do
      expect { do_request }.to change(BotCollaborator, :count).by(1)
      bc = BotCollaborator.last

      expect(bc.confirmed_at).to_not be_nil
      expect(bc.user).to eql user
      expect(bc.bot).to eql Bot.last
    end

    it 'should create default dashboards' do
      do_request
      b = Bot.last
      expect(b.dashboards.order("id").pluck(:dashboard_type)).to eql Dashboard::DEFAULT_FACEBOOK_DASHBOARDS
      expect(b.dashboards.pluck(:default).uniq).to eql [true]
    end

    it 'should redirect to bot_path' do
      do_request
      bot = user.bots.last
      expect(response).to redirect_to bot_path(bot)
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
    end
  end

  describe 'GET show' do
    before do
      sign_in user
    end

    def do_request
      get :show, id: bot.to_param
    end

    context 'if there are no bot instances' do
      it 'should redirect to the new_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_bot_instance_path(bot)
      end
    end

    context 'if there are bot instances (that are pending)' do
      let!(:bi1) { create :bot_instance, bot: bot }

      it 'should redirect to the new_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_bot_instance_path(bot)
      end
    end

    context 'if there are bot instances (that are disabled)' do
      let!(:bi1) { create :bot_instance, bot: bot, state: 'disabled' }

      it 'should render template :show' do
        do_request
        expect(response).to redirect_to bot_dashboards_path(bot)
      end
    end
  end

  describe 'GET edit' do
    before do
      sign_in user
    end

    def do_request
      get :edit, id: bot.to_param
    end

    it 'should render template :edit' do
      do_request
      expect(response).to render_template :edit
    end
  end

  describe 'PATCH update' do
    before do
      sign_in user
    end

    let!(:bot_params) { { name: 'Nestor Dev', webhook_url: 'https://example.com' } }

    def do_request
      patch :update, id: bot.to_param, bot: bot_params
    end

    it 'should update the name of the bot' do
      expect {
        do_request
        bot.reload
      }.to change(bot, :name).to('Nestor Dev').and change(bot, :webhook_url).to('https://example.com')
    end

    it 'should redirect to bot_verifying_webhook_path' do
      do_request

      expect(response).to redirect_to bot_verifying_webhook_path(bot)
    end

    context 'without webhook url changes' do
      let!(:bot_params) { { name: 'test', webhook_url: '' } }

      it 'should redirect to bot_path' do
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
    end
  end

  describe 'GET verifying_webhook' do
    before do
      sign_in user
    end

    def do_request
      get :verifying_webhook, bot_id: bot.to_param
    end

    it 'should invoke ValidateWebhookAndUpdatesJob' do
      allow(ValidateWebhookAndUpdatesJob).to receive(:perform_in)

      do_request

      expect(ValidateWebhookAndUpdatesJob).to have_received(:perform_in)
    end
  end

  describe 'GET webhook_events' do
    before do
      sign_in user
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
