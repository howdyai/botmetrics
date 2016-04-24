class BotUser < ActiveRecord::Base
  validates_presence_of :uid, :membership_type, :bot_instance_id
  belongs_to :bot_instance
end
