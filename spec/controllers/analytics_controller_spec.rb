RSpec.describe AnalyticsController do
  describe 'GET index' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot  }

    before do
      sign_in user
    end

    def do_request
      get :index, id: bot.to_param
    end

    it 'success' do
      expect(response).to be_success
    end
  end
end
