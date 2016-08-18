FactoryGirl.define do
  factory :dashboard do
    sequence(:name)     { |n| "Dashboard #{n}" }
    provider            'facebook'
    association(:bot)   { create :bot }
    association(:user)  { create :user }
  end
end
