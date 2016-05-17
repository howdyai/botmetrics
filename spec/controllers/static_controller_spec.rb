require 'rails_helper'

RSpec.describe StaticController do
  describe 'GET index' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

    before do
      sign_in user
      do_request
    end

    def do_request
      get :index
    end

    it 'redirects' do
      expect(response).to redirect_to bot_path(user.bots.first)
    end
  end
end
