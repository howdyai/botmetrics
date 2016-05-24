class Bot < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of   :name, :provider
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  has_many :instances, class_name: 'BotInstance'

  has_many :bot_collaborators
  has_many :collaborators, through: :bot_collaborators, source: :user
  has_many :owners, -> { where("bot_collaborators.collaborator_type" => 'owner') }, through: :bot_collaborators, source: :user

  has_many :notifications
end
