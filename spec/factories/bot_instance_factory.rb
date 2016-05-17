FactoryGirl.define do
  factory :bot_instance do
    sequence(:token) { |n| "bot-instance-token-#{n}" }
    provider         "slack"
    bot
  end
end
