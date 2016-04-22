class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      team = Team.create!(name: 'My Team')
      resource.team_memberships.create!(team: team, membership_type: 'owner')
    end
  end

  protected
  def sign_up_params
    params.require(:user).permit(:full_name, :email, :password)
  end

  def after_sign_up_path_for(resource)
    team_path(resource.teams.first)
  end
end
