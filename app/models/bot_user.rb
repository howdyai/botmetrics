class BotUser < ActiveRecord::Base
  belongs_to :bot_instance
  has_many :events

  validates_presence_of :uid, :membership_type, :bot_instance_id, :provider
  validates_uniqueness_of :uid, scope: :bot_instance_id
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  scope :user_attributes_eq, ->(field, value) do
    where(
      "bot_users.user_attributes->>:field = :value",
      field: field,
      value: value
    )
  end

  scope :user_attributes_cont, ->(field, value) do
    where(
      "bot_users.user_attributes->>:field ILIKE :value",
      field: field,
      value: "%#{value}%"
    )
  end

  scope :interaction_count_eq, ->(count)do
    where("bot_interaction_count = ?", count)
  end

  scope :interaction_count_lt, ->(count)do
    where("bot_interaction_count < ?", count)
  end

  scope :interaction_count_gt, ->(count)do
    where("bot_interaction_count > ?", count)
  end

  scope :interaction_count_betw, ->(min, max)do
    where('bot_interaction_count BETWEEN ? AND ?', min, max)
  end

  scope :interacted_at_betw, ->(min, max) do
    where('last_interacted_with_bot_at BETWEEN ? AND ?', min, max).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :interacted_at_lt, ->(days_ago) do
    where('last_interacted_with_bot_at > ?', days_ago).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :interacted_at_gt, ->(days_ago) do
    where('last_interacted_with_bot_at < ?', days_ago).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :user_signed_up_gt, ->(days_ago) do
    where('created_at < ?', days_ago)
  end

  scope :user_signed_up_lt, ->(days_ago) do
    where('created_at > ?', days_ago)
  end

  scope :user_signed_up_betw, ->(min, max) do
    where(created_at: min..max)
  end

  store_accessor :user_attributes, :nickname, :email, :full_name, :first_name, :last_name, :gender

  def self.with_bot_instances(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id)).joins(:bot_instance).
      where("bot_instances.created_at" => start_time..end_time)
  end
end
