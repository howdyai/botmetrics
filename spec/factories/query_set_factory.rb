FactoryGirl.define do
  factory :query_set do
    instances_scope { [:legit, :enabled].sample }
    time_zone 'Pacific/Asia'

    trait :with_slack_queries do
      queries { build_list(:slack_query, 1) }
    end
  end
end
