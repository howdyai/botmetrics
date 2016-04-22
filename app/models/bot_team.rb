class BotTeam < ActiveRecord::Base
  validates_presence_of :uid, :bot_instance_id
  belongs_to :bot_instance
end
