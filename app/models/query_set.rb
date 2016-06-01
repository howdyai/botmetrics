class QuerySet < ActiveRecord::Base
  has_many :queries

  accepts_nested_attributes_for :queries
end
