FactoryGirl.define do
  factory :team_membership do
    association :user, factory: :user
    association :team, factory: :team
    membership_type 'member'
  end
end
