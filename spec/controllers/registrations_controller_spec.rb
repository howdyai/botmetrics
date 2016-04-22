require 'spec_helper'

describe RegistrationsController do
  # needed for devise shit
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST#create' do
    let!(:user_attributes) do
      {
        email: 'i@mclov.in',
        full_name: 'Mclovin',
        password: 'password'
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
    end

    it 'should create a new team' do
      expect { do_request }.to change(Team, :count).by(1)
      team = Team.last
      expect(team.name).to eql 'My Team'
      expect(team.members).to match_array [User.find_by(email: 'i@mclov.in')]
      expect(team.owners).to match_array [User.find_by(email: 'i@mclov.in')]
    end

    it 'should redirect to the team_path' do
      do_request
      team = Team.last
      expect(response).to redirect_to team_path(team)
    end
  end
end
