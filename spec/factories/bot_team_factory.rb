FactoryGirl.define do
  factory :bot_team do
    sequence(:uid)             { |n| "bot-team-uid-#{n}" }
    association(:bot_instance) { create :bot_instance }
  end
end
