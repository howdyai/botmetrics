class Team < ActiveRecord::Base
  before_validation :set_uid!

  validates_presence_of :name
  validates_uniqueness_of :uid

  has_many :team_memberships
  has_many :members, through: :team_memberships, source: :user
  has_many :owners, -> { where("team_memberships.membership_type = ?", 'owner') }, through: :team_memberships, source: :user

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
