FactoryGirl.define do
  factory :slack_query, class: Query do
    provider 'slack'
    add_attribute :field, 'nickname'
    add_attribute :method, 'contains'
    add_attribute :value, 'win'
  end
end
