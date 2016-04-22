class Team < ActiveRecord::Base
  before_validation :set_uid!

  validates_presence_of :name
  validates_uniqueness_of :uid

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
