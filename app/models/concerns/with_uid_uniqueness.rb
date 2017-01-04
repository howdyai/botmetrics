module WithUidUniqueness
  extend ActiveSupport::Concern

  included do
    before_validation :set_uid!
    validates_uniqueness_of :uid
  end

  def to_param
    self.uid
  end

  protected
  def set_uid!
    self.uid = SecureRandom.hex(6) if self.uid.blank?
  end
end
