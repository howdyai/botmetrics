FactoryGirl.define do
  factory :user do
    sequence(:email)    { |n| "user-#{n}@getbotmetrics.com" }
    sequence(:password) { |n| "password-#{n}#{n+1}#{n+2}" }
  end
end
