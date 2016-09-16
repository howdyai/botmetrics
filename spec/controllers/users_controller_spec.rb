RSpec.describe UsersController do
  let!(:user) { create :user }

  before { sign_in user }

  describe '#update' do
    let(:params) do
      {
        user:
          {
            created_bot_instance:  '0',
            disabled_bot_instance: '0',
            daily_reports:         '0'
          }
      }
    end

    def do_request
      post :update, { id: user.to_param }.merge(params)
    end

    it 'updates email preferences' do
      params[:user].each { |pref, _| expect(user.send(pref)).to eq('1'), pref.to_s }

      do_request

      params[:user].each { |pref, _| expect(user.reload.send(pref)).to eq('0'), pref.to_s }
    end
  end

  describe 'PATCH regenerate_api_key' do
    def do_request
      patch :regenerate_api_key, id: user.to_param
    end

    it 'should change the API key of the user' do
      expect {
        do_request
        user.reload
      }.to change(user, :api_key)

      expect(user.api_key).to_not be_blank
    end

    it 'should redirect back to the user profile path' do
      do_request
      expect(response).to redirect_to user_path(user)
    end
  end
end
