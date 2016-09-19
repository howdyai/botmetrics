FactoryGirl.define do
  factory :setting do
    sequence(:key)    { |n| "key #{n}" }
    sequence(:value)  { |n| "value #{n}" }
  end
end
