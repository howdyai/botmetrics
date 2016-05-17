FactoryGirl.define do
  factory :bot_user do
    sequence(:uid)   { |n| "bot-user-uid-#{n}" }
    membership_type  'member'
    provider         'slack'

    bot_instance

    trait :with_attributes do
      user_attributes do
        {
          'nickname'             => 'johnson',
          'email'                => 'johnson@example.com',
          'first_name'           => nil,
          'last_name'            => nil,
          'full_name'            => '',
          'timezone'             => 'America/Los_Angeles',
          'timezone_description' => 'Pacific Daylight Time',
          'timezone_offset'      => -25200
        }
      end
    end
  end
end
