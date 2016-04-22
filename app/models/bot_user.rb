class BotUser < ActiveRecord::Base
  validates_presence_of :uid, :membership_type, :bot_team_id
  belongs_to :bot_team
end
