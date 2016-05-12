class Bot < ActiveRecord::Base
  before_validation :set_uid!

  validates_presence_of   :name, :provider
  validates_uniqueness_of :uid
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  has_many :instances, class_name: 'BotInstance'

  has_many :bot_collaborators
  has_many :collaborators, through: :bot_collaborators, source: :user
  has_many :owners, -> { where("bot_collaborators.collaborator_type" => 'owner') }, through: :bot_collaborators, source: :user

  has_many :notifications

  def to_param
    self.uid
  end

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
