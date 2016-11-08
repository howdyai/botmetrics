class ShortLink < ActiveRecord::Base
  validates_presence_of :url, :bot_user_id, :bot_instance_id
  validates_uniqueness_of :slug
  before_save :make_slug
  belongs_to :bot_instance
  belongs_to :bot_user

  def make_slug
    unless self.slug
      self.slug = SecureRandom.hex(8)
    end
  end 

end
