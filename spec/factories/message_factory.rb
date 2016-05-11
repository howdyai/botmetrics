FactoryGirl.define do
  factory :message do
    association :bot_instance, factory: :bot_instance

    trait :to_channel do
      message_attributes({ team_id: 'T123', channel: 'C1234' })
      text 'ok!'
    end

    trait :to_user do
      message_attributes({ team_id: 'T123', user: 'U1234' })
      text 'ok!'
    end
  end
end
