FactoryGirl.define do
  sequence(:event_attributes) {
    Hash(
      channel: SecureRandom.hex(8),
      timestamp: Time.current.to_i, delivered: false,
      mid: 'mid',
      seq: 74
    )
  }

  factory :event do
    bot_instance
    event_type 'user_added'
    provider   'slack'

    trait :facebook do
      provider 'facebook'
    end
  end

  factory :new_bot_event, parent: :event do
    event_type { 'message' }
    is_for_bot { true }
    event_attributes
  end

  factory :disabled_bots_event, parent: :event do
    event_type { 'bot_disabled' }
  end

  factory :all_messages_event, parent: :event do
    event_type          { 'message' }
    is_from_bot         { false }
    association :user,   factory: :bot_user
    event_attributes
  end

  factory :messages_to_bot_event, parent: :event do
    event_type          { 'message' }
    is_for_bot          { true }
    association :user,   factory: :bot_user
    event_attributes
  end

  factory :messages_from_bot_event, parent: :event do
    event_type          { 'message' }
    is_from_bot         { true }
    association :user,   factory: :bot_user
    event_attributes
  end
end
