require 'spec_helper'

describe TeamsController do
  let!(:user) { create :user }
  let!(:team) { create :team }
  let!(:tm1)  { create :team_membership, team: team, user: user }

  describe 'GET show' do
    before { sign_in user }

    def do_request
      get :show, id: team.to_param
    end

    let!(:bot) { create :bot, team: team }

    it 'should redirect to the team_bot_path for the bot' do
      do_request
      expect(response).to redirect_to team_bot_path(team, bot)
    end
  end
end
