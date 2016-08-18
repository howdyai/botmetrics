FactoryGirl.define do
  factory :dashboard do
    sequence(:name)     { |n| "Dashboard #{n}" }
    dashboard_type      'messages-to-bot'
    provider            'facebook'
    association(:bot)   { create :bot }
    association(:user)  { create :user }
  end
end
