FactoryGirl.define do
  factory :rolledup_event do
    association :bot_instance, factory: :bot_instance
    association :dashboard, factory: :dashboard
    created_at  { Time.now.beginning_of_hour }
  end
end
