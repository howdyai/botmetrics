RSpec.describe BotInstancesController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

  describe 'GET new' do
    before { sign_in user }

    def do_request
      get :new, bot_id: bot.to_param
    end

    it 'should render template :new' do
      do_request
      expect(response).to render_template :new
    end

    it "should set instance variable '@instance'" do
      do_request
      expect(assigns(:instance)).to_not be_nil
    end
  end

  describe 'POST create' do
    let(:bot_instance_params) { { token: 'token-deadbeef' } }

    before do
      allow(SetupBotJob).to receive(:perform_async)
    end

    shared_examples 'creates and sets up a bot' do
      it 'should create a new bot instance' do
        expect {
          do_request
          bot.reload
        }.to change(bot.instances, :count).by(1)

        instance = bot.instances.last
        expect(instance.token).to eql 'token-deadbeef'
        expect(instance.provider).to eql bot.provider
      end

      it 'calls SetupBotJob' do
        do_request

        instance = bot.instances.last
        expect(SetupBotJob).to have_received(:perform_async).with(instance.id, user.id)
      end
    end

    context 'format html' do
      before { sign_in user }

      def do_request
        post :create, instance: bot_instance_params, bot_id: bot.to_param
      end

      it_behaves_like 'creates and sets up a bot'

      it "should redirect back to setting_bot_instance_path" do
        do_request
        instance = bot.instances.last
        expect(response).to redirect_to setting_up_bot_instance_path(bot, instance)
      end
    end

    context 'format json' do
      before { request.headers['Authorization'] = JsonWebToken.encode('user_id' => user.id) }

      def do_request
        post :create, instance: bot_instance_params, bot_id: bot.to_param, format: :json
      end

      it_behaves_like 'creates and sets up a bot'

      it "should respond with JSON object containing the id of the instance" do
        do_request

        expect(response).to have_http_status :created

        body = JSON.parse(response.body)
        expect(body['id']).to eql bot.instances.last.id
      end

      context 'when created_at is sent' do
        let(:bot_instance_params) { { token: 'token-deadbeef', created_at: created_at } }
        let(:created_at) { 5.days.ago.to_i }

        it 'sets the created_at timestamp to the one specified by the user' do
          do_request

          instance = bot.instances.last
          expect(instance.created_at.to_i).to eql created_at
        end
      end
    end
  end

  describe 'GET edit' do
    let!(:instance) { create :bot_instance, bot: bot }

    before { sign_in user }

    def do_request
      get :edit, bot_id: bot.to_param, id: instance.to_param
    end

    context "bot provider is facebook" do
      before { bot.update_attribute(:provider, 'facebook') }

      it 'should render template :edit' do
        do_request
        expect(response).to render_template :edit
      end

      it "should set instance variable '@instance'" do
        do_request
        expect(assigns(:instance)).to_not be_nil
      end
    end

    context "bot provider is not slack" do
      it 'should redirect to bot_path(bot)' do
        do_request
        expect(response).to redirect_to bot_path(bot)
      end
    end
  end

  describe 'PATCH update' do
    let!(:instance) { create :bot_instance, bot: bot, provider: 'facebook' }
    let(:bot_instance_params) { { token: 'token-deadbeef' } }

    before do
      bot.update_attribute(:provider, 'facebook')
      allow(SetupBotJob).to receive(:perform_async)
    end

    shared_examples 'updates and sets up a bot' do
      it 'should update a the bot instance' do
        expect {
          do_request
          instance.reload
        }.to change(instance, :token).to('token-deadbeef')

        expect(instance.provider).to eql bot.provider
      end

      it 'calls SetupBotJob' do
        do_request
        expect(SetupBotJob).to have_received(:perform_async).with(instance.id, user.id)
      end
    end

    context 'bot is not by facebook' do
      before { sign_in user }

      def do_request
        patch :update, instance: bot_instance_params, bot_id: bot.to_param, id: instance.to_param
      end

      before { bot.update_attribute(:provider, 'slack') }

      it "should redirect back to bot_path" do
        do_request
        expect(response).to redirect_to bot_path(bot)
      end
    end

    context 'format html' do
      before { sign_in user }

      def do_request
        patch :update, instance: bot_instance_params, bot_id: bot.to_param, id: instance.to_param
      end

      it_behaves_like 'updates and sets up a bot'

      it "should redirect back to setting_bot_instance_path" do
        do_request
        expect(response).to redirect_to setting_up_bot_instance_path(bot, instance)
      end
    end
  end
end
