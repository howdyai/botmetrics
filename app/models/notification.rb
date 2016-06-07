class Notification < ActiveRecord::Base
  include WithUidUniqueness

  belongs_to :bot

  has_one :query_set, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates_presence_of :content

  with_options on: :schedule do |n|
    n.validate :verify_scheduled_at
  end

  def send_immediately?
    scheduled_at.blank?
  end

  def sent?
    return true if scheduled_at.blank?

    schedule_at_in_past?
  end

  private

    def verify_scheduled_at
      return if scheduled_at.blank?

      if schedule_at_in_past?
        errors.add(:scheduled_at, 'has already past in some time zones')
      end
    end

    def schedule_at_in_past?
      scheduled_at.in_time_zone('Pacific/Apia').past?
    end
end
