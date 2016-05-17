RSpec.describe UsersController do
  let!(:user) { create :user }

  describe 'PATCH regenerate_api_key' do
    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

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
