FactoryGirl.define do
  factory :bot do
    sequence(:name) { |n| "Bot #{n}" }
    provider        "slack"

    trait :with_owners do
      owners { build_list(:user, 2) }
    end

    trait :with_uid do
      sequence(:uid) { |n| "123123#{n}qwe#{n}" }
    end
  end
end
