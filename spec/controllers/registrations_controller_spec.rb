RSpec.describe RegistrationsController do
  # needed for devise shit
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'GET#new' do
    def do_request
      get :new
    end

    context 'when an admin user is created' do
      let!(:user) { create :user }

      it 'should render redirect to root_path' do
        do_request
        expect(response).to redirect_to root_path
      end
    end

    context 'when an admin user is not created yet' do
      it 'should render template :new' do
        do_request
        expect(response).to render_template :new
      end
    end
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

    context 'when an admin user is created' do
      let!(:user) { create :user }

      it 'should not create a new user' do
        expect { do_request }.to_not change(User, :count)
      end

      it 'should redirect to root_path' do
        do_request
        expect(response).to redirect_to root_path
      end
    end

    context 'when an admin user is not created yet' do
      it 'creates a new user' do
        expect { do_request }.to change(User, :count).by(1)

        user = User.last
        expect(user.full_name).to eql 'Mclovin'
        expect(user.email).to eql 'i@mclov.in'
        expect(user.timezone).to eql 'Pacific Time (US & Canada)'
        expect(user.timezone_utc_offset).to eql -28800
        expect(user.api_key).to_not be_blank
        expect(user.signed_up_at).to_not be_nil
        expect(user.site_admin).to be_truthy
      end

      it 'should redirect to new_setting_path' do
        do_request
        bot = Bot.last
        expect(response).to redirect_to new_setting_path
      end
    end
  end
end
