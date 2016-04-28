require 'spec_helper'

describe BotsController do
  let!(:user) { create :user }
  let!(:team) { create :team }
  let!(:bot)  { create :bot, team: team }
  let!(:tm1)  { create :team_membership, team: team, user: user }

  describe 'GET show' do
    before { sign_in user }

    def do_request
      get :show, team_id: team.to_param, id: bot.to_param
    end

    context 'if there are no bot instances' do
      it 'should redirect to the new_team_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_team_bot_instance_path(team, bot)
      end
    end

    context 'if there are bot instances (that are pending)' do
      let!(:bi1) { create :bot_instance, bot: bot }

      it 'should redirect to the new_team_bot_instance_path for the bot' do
        do_request
        expect(response).to redirect_to new_team_bot_instance_path(team, bot)
      end
    end

    context 'if there are bot instances (that are disabled)' do
      let!(:bi1) { create :bot_instance, bot: bot, state: 'disabled' }

      it 'should render template :show' do
        do_request
        expect(response).to render_template :show
      end
    end
  end

  describe 'GET edit' do
    before { sign_in user }

    def do_request
      get :edit, team_id: team.to_param, id: bot.to_param
    end

    it 'should render template :edit' do
      do_request
      expect(response).to render_template :edit
    end
  end

  describe 'PATCH update' do
    before { sign_in user }

    let!(:bot_params) { { name: 'Nestor Dev' } }

    def do_request
      patch :update, team_id: team.to_param, id: bot.to_param, bot: bot_params
    end

    it 'should update the name of the bot' do
      expect {
        do_request
        bot.reload
      }.to change(bot, :name).to('Nestor Dev')
    end

    it 'should redirect to team_bot_path' do
      do_request
      expect(response).to redirect_to team_bot_path(team, bot)
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
end
