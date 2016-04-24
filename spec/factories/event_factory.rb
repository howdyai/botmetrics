FactoryGirl.define do
  factory :event do
    association :bot_instance, factory: :bot_instance
    event_type 'user_added'
    provider   'slack'
  end
end
