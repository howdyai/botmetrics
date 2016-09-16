RSpec.describe RegistrationsController do
  # needed for devise shit
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST#create' do
    let!(:user_attributes) do
      {
        email: 'i@mclov.in',
        full_name: 'Mclovin',
        password: 'password',
        timezone: 'Pacific Time (US & Canada)'
      }
    end

    def do_request
      post :create, user: user_attributes
    end

    it 'creates a new user' do
      expect { do_request }.to change(User, :count).by(1)

      user = User.last
      expect(user.full_name).to eql 'Mclovin'
      expect(user.email).to eql 'i@mclov.in'
      expect(user.timezone).to eql 'Pacific Time (US & Canada)'
      expect(user.timezone_utc_offset).to eql -28800
      expect(user.api_key).to_not be_blank
      expect(user.signed_up_at).to_not be_nil
    end

    it 'should redirect to new_bot_path' do
      do_request
      bot = Bot.last
      expect(response).to redirect_to new_bot_path
    end
  end
end
