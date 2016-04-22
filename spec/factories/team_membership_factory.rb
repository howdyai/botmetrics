FactoryGirl.define do
  factory :team_membership do
    association(:user) { create :user }
    association(:team) { create :team }
    membership_type 'member'
  end
end
