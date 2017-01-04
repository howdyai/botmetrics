FactoryGirl.define do
  factory :funnel do
    association :bot, factory: :bot
    association :creator, factory: :user
    sequence(:name) { |n| "Funnel #{n}" }
    dashboards {
                 ["dashboard:#{create(:dashboard, bot: self.bot).uid}",
                  "dashboard:#{create(:dashboard, bot: self.bot).uid}"
                 ]
               }
  end
end
