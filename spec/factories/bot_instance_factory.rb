FactoryGirl.define do
  factory :bot_instance do
    sequence(:token)  { |n| "bot-instance-token-#{n}" }
    provider          "slack"
    bot

    trait :with_attributes do
      instance_attributes do
        {
          'team_id'   => 'T123',
          'team_name' => 'T123',
          'team_url'  => 'https://T123.slack.com'
        }
      end
    end

    trait :with_attributes_facebook do
      instance_attributes do
        { 'name' => 'N123' }
      end
    end

    trait :with_attributes_kik do
      uid 'U12345'
      instance_attributes do
        {
          'webhook' => 'webhook',
          'features' => {
            'receiveReadReceipts' => false,
            'receiveIsTyping' => false,
            'manuallySendReadReceipts' => false,
            'receiveDeliveryReceipts' => false
          }
        }
      end
    end
  end
end
