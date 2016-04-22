class Bot < ActiveRecord::Base
  before_validation :set_uid!

  validates_presence_of   :name, :team_id, :provider
  validates_uniqueness_of :uid
  validates_inclusion_of  :provider, in: %w(slack kik messenger telegram)

  belongs_to :team

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
