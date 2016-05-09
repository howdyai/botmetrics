FactoryGirl.define do
  factory :bot_collaborator do
    association :user, factory: :user
    association :bot,  factory: :bot
    collaborator_type 'owner'
  end
end
