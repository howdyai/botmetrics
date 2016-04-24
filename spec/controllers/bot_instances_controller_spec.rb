require 'spec_helper'

describe BotInstancesController do
  let!(:user) { create :user }
  let!(:team) { create :team }
  let!(:bot)  { create :bot, team: team }
  let!(:tm1)  { create :team_membership, team: team, user: user }

  describe 'GET new' do
    before { sign_in user }

    def do_request
      get :new, team_id: team.to_param, bot_id: bot.to_param
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
    before { sign_in user }
    let!(:bot_instance_params) { { token: 'token-deadbeef', uid: 'UNESTOR1' } }

    def do_request
      post :create, instance: bot_instance_params, team_id: team.to_param, bot_id: bot.to_param
    end

    it 'should create a new bot instance' do
      expect {
        do_request
        bot.reload
      }.to change(bot.instances, :count).by(1)

      instance = bot.instances.last
      expect(instance.token).to eql 'token-deadbeef'
      expect(instance.uid).to eql 'UNESTOR1'
      expect(instance.provider).to eql bot.provider
    end

    it "should redirect back to team_bot_path" do
      do_request
      expect(response).to redirect_to team_bot_path(team, bot)
    end
  end
end
