class Message < ActiveRecord::Base
  belongs_to :bot_instance

  validates_presence_of :bot_instance

  def team_id
    message_attributes['team_id']
  end

  def channel
    message_attributes['channel']
  end
end
