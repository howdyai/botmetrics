class Message < ActiveRecord::Base
  belongs_to :bot_instance

  validates_presence_of :bot_instance

  before_create :duplicate_provider_from_bot_instance

  def team_id
    message_attributes['team_id']
  end

  def channel
    message_attributes['channel']
  end

  def user
    message_attributes['user']
  end

  private

    def duplicate_provider_from_bot_instance
      self.provider = bot_instance.provider
    end
end
