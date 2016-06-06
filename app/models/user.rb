# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :bot_collaborators
  has_many :bots, through: :bot_collaborators

  validates_uniqueness_of :api_key, if: Proc.new { |u| u.api_key.present? }

  before_create :init_email_preferences

  store_accessor :email_preferences, :created_bot_instance, :disabled_bot_instance, :daily_reports
  store_accessor :tracking_attributes, :last_daily_summary_sent_at

  scope :subscribed_to, ->(email_preference) do
    where('email_preferences @> ?', { email_preference => '1' }.to_json)
  end

  def self.local_time_is_after(hour)
    where(timezone: ActiveSupport::TimeZone.zones_after(hour))
  end

  def to_param
    'me'
  end

  def set_api_key!
    self.api_key = JsonWebToken.encode({'user_id' => self.id}, 10.years.from_now)
  end

  def can_send_daily_summary?
    last_daily_summary_sent_at.present? &&
    last_daily_summary_sent_at.to_i < (Time.now.in_time_zone(timezone) - 24.hours).to_i
  end

  def subscribed?
    daily_reports == '1'
  end

  private

    def init_email_preferences
      self.email_preferences['created_bot_instance']  ||= '1'
      self.email_preferences['disabled_bot_instance'] ||= '1'
      self.email_preferences['daily_reports']         ||= '1'
    end
end
