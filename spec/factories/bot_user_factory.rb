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

    trait :with_facebook_attributes do
      user_attributes do
        {
          'first_name'           => Faker::Name.first_name,
          'last_name'            => Faker::Name.last_name,
          'gender'               => ['male', 'female'].sample,
          'profile_pic'          => Faker::Avatar.image,
          'locale'               => 'en/US',
          'timezone'             => -8
        }
      end
    end
  end
end
