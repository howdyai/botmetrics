class Query
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :field, :method, :value

  validates_presence_of  :field
  validates_inclusion_of :field, in: %w(nickname email full_name)
  validates_presence_of  :method
  validates_inclusion_of :method, in: %w(equals_to contains)
  validates_presence_of  :value
end
