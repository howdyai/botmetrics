FactoryGirl.define do
  factory :notification do
    content       'Hello World!'
    bot_user_ids  [1,2]
  end
end
