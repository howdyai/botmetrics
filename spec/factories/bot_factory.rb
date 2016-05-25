FactoryGirl.define do
  factory :bot do
    sequence(:name) { |n| "Bot #{n}" }
    provider        "slack"
    webhook_url     "https://nestor.com/webhook"

    trait :with_owners do
      owners { build_list(:user, 2) }
    end
  end
end
