FactoryGirl.define do
  factory :bot_user do
    sequence(:uid)             { |n| "bot-user-uid-#{n}" }
    membership_type            'member'
    provider                   'slack'

    bot_instance
  end
end
