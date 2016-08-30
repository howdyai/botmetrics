FactoryGirl.define do
  factory :slack_query, class: Query do
    provider 'slack'
    add_attribute :field, 'nickname'
    add_attribute :method, 'contains'
    add_attribute :value, 'win'
  end

  factory :facebook_query, class: Query do
    provider 'facebook'
    add_attribute :field, 'first_name'
    add_attribute :method, 'contains'
    add_attribute :value, 'win'
  end
end
