FactoryGirl.define do
  sequence(:event_attributes) {
    Hash(
      channel: SecureRandom.hex(8),
      timestamp: Time.current.to_i, delivered: false,
      mid: 'mid',
      seq: SecureRandom.hex(8)
    )
  }

  factory :event do
    bot_instance

    event_type 'message'
    provider   'slack'
    event_attributes
    association :user,   factory: :bot_user

    trait :facebook do
      provider 'facebook'
    end
  end

  factory :new_bot_event, parent: :event do
    event_type { 'bot-installed' }
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

  factory :facebook_image_event, parent: :event do
    event_type          { 'message:image-uploaded' }
    is_for_bot          { true }
    association :user,   factory: :bot_user
    provider            'facebook'
    sequence(:event_attributes) do |n|
      Hash(
        mid: 'mid',
        seq: n,
        attachments: [{type: 'image'}]
      )
    end
  end

  factory :kik_image_event, parent: :event do
    event_type          { 'message:image-uploaded' }
    is_for_bot          { true }
    association :user,   factory: :bot_user
    provider            'kik'
    sequence(:event_attributes) do |n|
      Hash(
        id: "id-#{n}",
        chat_id: "chat-id-#{n}",
        sub_type: 'picture'
      )
    end
  end

  factory :messages_from_bot_event, parent: :event do
    event_type          { 'message' }
    is_from_bot         { true }
    association :user,   factory: :bot_user
    event_attributes
  end
end
