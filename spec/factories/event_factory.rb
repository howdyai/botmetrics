FactoryGirl.define do
  factory :event do
    bot_instance
    event_type 'user_added'
    provider   'slack'
  end
end
