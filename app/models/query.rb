class Query < ActiveRecord::Base
  FIELDS  = {
    'nickname'  => 'Nickname',
    'email'     => 'Email',
    'full_name' => 'Full Name'
  }
  METHODS = {
    'equals_to' => 'Equals To',
    'contains'  => 'Contains'
  }

  belongs_to :query_set

  validates_presence_of  :field
  validates_inclusion_of :field,  in: FIELDS.keys
  validates_presence_of  :method
  validates_inclusion_of :method, in: METHODS.keys
  validates_presence_of  :value

  def sql_params
    case method
      when 'equals_to'
        [
          "bot_users.user_attributes->>:field = :value",
         field: field,
         value: value
        ]
      when 'contains'
        [
          "bot_users.user_attributes->>:field ILIKE :value",
          field: field,
          value: "%#{value}%"
        ]
    end
  end
end
