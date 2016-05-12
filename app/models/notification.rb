class Notification < ActiveRecord::Base
  belongs_to :bot
  has_many :messages

  validates_presence_of :content
end
