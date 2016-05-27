class Bot < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of  :name, :provider
  validates_inclusion_of :provider, in: %w(slack kik facebook telegram)
  validates_format_of    :webhook_url, with: %r(\Ahttps://), if: ->(record) { record.webhook_url.present? }

  has_many :instances, class_name: 'BotInstance'

  has_many :bot_collaborators
  has_many :collaborators, through: :bot_collaborators, source: :user
  has_many :owners, -> { where("bot_collaborators.collaborator_type" => 'owner') }, through: :bot_collaborators, source: :user

  has_many :notifications
  has_many :webhook_events
end
