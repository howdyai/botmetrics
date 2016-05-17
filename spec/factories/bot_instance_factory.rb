FactoryGirl.define do
  factory :bot_instance do
    sequence(:token)  { |n| "bot-instance-token-#{n}" }
    provider          "slack"
    bot

    trait :with_attributes do
      instance_attributes do
        {
          'team_id' => 'T123'
        }
      end
    end
  end
end
