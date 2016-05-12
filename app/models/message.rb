class Message < ActiveRecord::Base
  belongs_to :bot_instance
  belongs_to :notification

  validates_presence_of :bot_instance

  scope :sent,    -> { where(sent: true) }
  scope :success, -> { sent.where(success: true) }
  scope :failure, -> { sent.where(success: false) }

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
