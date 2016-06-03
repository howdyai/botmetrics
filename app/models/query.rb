class Query < ActiveRecord::Base
  FIELDS  = {
    'nickname'          => 'Nickname',
    'email'             => 'Email',
    'full_name'         => 'Full Name',
    'interaction_count' => 'Number of Interactions with Bot',
    'interacted_at'     => 'Interacted With Bot',
    'user_created_at'   => 'User Signed Up At',
  }

  STRING_METHODS = {
    'equals_to' => 'Equals To',
    'contains'  => 'Contains'
  }

  NUMBER_METHODS = {
    'equals_to' => 'Equals To',
    'between'   => 'Between'
  }

  DATETIME_METHODS = {
    'between'   => 'Between'
  }

  belongs_to :query_set

  validates_presence_of  :field
  validates_inclusion_of :field,  in: FIELDS.keys
  validates_presence_of  :method
  validates_inclusion_of :method, in: STRING_METHODS.keys | NUMBER_METHODS.keys
  validates_presence_of  :value, if: Proc.new { |query| query.method != 'between' }
  validates_presence_of  :min_value, if: Proc.new { |query| query.method == 'between' }
  validates_presence_of  :max_value, if: Proc.new { |query| query.method == 'between' }

  def is_string_query?
    field.in?(['nickname', 'email', 'full_name'])
  end

  def is_number_query?
    field.in?(['interaction_count'])
  end

  def is_datetime_query?
    field.in?(['interacted_at', 'user_created_at'])
  end
end
