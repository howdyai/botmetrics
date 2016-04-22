FactoryGirl.define do
  factory :bot do
    sequence(:name)     { |n| "Bot #{n}" }
    provider            "slack"
    association(:team)  { create :team }
  end
end
