class BotInstance < ActiveRecord::Base
  validates_presence_of :uid, :token, :bot_id
  validates_uniqueness_of :uid, :token
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  belongs_to :bot
  has_many :users, class_name: 'BotUser'
end
