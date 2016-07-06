FactoryGirl.define do
  factory :user do
    sequence(:email)    { |n| "user-#{n}@getbotmetrics.com" }
    sequence(:password) { |n| "password-#{n}#{n+1}#{n+2}" }
    timezone  "Pacific Time (US & Canada)"
    timezone_utc_offset -28800
    signed_up_at        { Time.now }
  end
end
