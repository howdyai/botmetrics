FactoryGirl.define do
  factory :rolledup_event do
    association :bot_instance, factory: :bot_instance
    association :dashboard, factory: :dashboard
    bot_instance_id_bot_user_id { "#{self.bot_instance.id}:#{self.bot_user_id}" }
    sequence(:created_at)       { |n| n.hours.from_now.beginning_of_hour }
  end
end
