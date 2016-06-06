# frozen_string_literal: true

class Message < ActiveRecord::Base
  belongs_to :bot_instance
  belongs_to :notification

  validates_presence_of :bot_instance

  scope :sent,      -> { where.not(sent_at: nil) }
  scope :success,   -> { sent.where(success: true) }
  scope :failure,   -> { sent.where(success: false) }
  scope :scheduled, -> { where(sent_at: nil).where.not(scheduled_at: nil) }

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

  def can_send_now?
    return false if sent_at

    scheduled_at <= Time.current
  end

  def ping_pusher_for_notification
    PusherJob.perform_async(
      "notification",
      "notification-#{notification.id}",
      {
        ok: success,
        recipient: (user || channel),
        sent: notification.messages.sent.count
      }.to_json
    )
  end

  def log_response(response)
    update(success: response['ok'], response: response)
  end

  private

    def duplicate_provider_from_bot_instance
      self.provider = bot_instance.provider
    end
end
