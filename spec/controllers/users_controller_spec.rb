RSpec.describe UsersController do
  let!(:user) { create :user }

  before { sign_in user }

  describe '#update' do
    let(:params) do
      {
        user:
          {
            created_bot_instance: '0',
            disabled_bot_instance: '0'
          }
      }
    end

    def do_request
      post :update, { id: user.to_param }.merge(params)
    end

    it 'updates email preferences' do
      expect(user.created_bot_instance).to eq '1'
      expect(user.disabled_bot_instance).to eq '1'

      do_request

      expect(user.reload.created_bot_instance).to eq '0'
      expect(user.reload.disabled_bot_instance).to eq '0'
    end
  end

  describe 'PATCH regenerate_api_key' do
    before { allow(TrackMixpanelEventJob).to receive(:perform_async) }

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

    it 'should track the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Regenerated API Key', user.id)
    end
  end
end
