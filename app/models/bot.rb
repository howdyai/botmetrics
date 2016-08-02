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

  def build_instance(params)
    fb_instance = instances.find_by(provider: :facebook)
    if fb_instance.present? && fb_instance.provider == provider
      return fb_instance.assign_attributes(params) || fb_instance
    end
    instances.build(params)
  end
end
