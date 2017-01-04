class ShortLink < ActiveRecord::Base
  validates_presence_of   :url, :bot_user_id, :bot_instance_id
  validates_uniqueness_of :slug
  validates :url, url: true

  before_validation       :set_slug

  belongs_to :bot_instance
  belongs_to :bot_user

  def set_slug
    self.slug = SecureRandom.hex(8) unless self.slug
  end

  def to_param
    self.slug
  end
end
