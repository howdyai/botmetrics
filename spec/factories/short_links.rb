FactoryGirl.define do
  factory :short_link do
    association(:bot_instance) { create :bot_instance }
    association(:bot_user)     { create :bot_user     }
    sequence(:url)             { |n| "http://localhost#{n}" }
  end
end
