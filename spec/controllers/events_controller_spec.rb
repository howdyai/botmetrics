require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  describe 'POST create' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot  }
    let!(:bc)   { create :bot_collaborator, bot: bot, user: user }

    def do_request(params = {})
      post :create, bot_id: bot.uid, event: params
    end

    before { sign_in user }

    it 'should respond with 201 created' do
      do_request
      expect(response).to have_http_status(:accepted)
    end
  end
end
