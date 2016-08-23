FactoryGirl.define do
  factory :dashboard_event do
    association :dashboard, factory: :dashboard
    association :event, factory: :event
  end
end
