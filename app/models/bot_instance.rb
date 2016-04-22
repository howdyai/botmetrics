class BotInstance < ActiveRecord::Base
  validates_presence_of :uid, :token, :bot_id
  validates_uniqueness_of :uid, :token

  belongs_to :bot
  has_one    :bot_team
end
