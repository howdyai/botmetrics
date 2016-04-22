class Bot < ActiveRecord::Base
  before_validation :set_uid!

  validates_presence_of   :name, :team_id, :provider
  validates_uniqueness_of :uid
  validates_inclusion_of  :provider, in: %w(slack kik messenger telegram)

  has_many :instances, class_name: 'BotInstance'
  belongs_to :team

  def to_param
    self.uid
  end

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
