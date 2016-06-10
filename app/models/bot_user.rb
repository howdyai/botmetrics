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
    joins(:events).
      where(events: { event_type: 'message', is_for_bot: true }).
      group('bot_users.id').
      having('count(*) = ?', count)
  end

  scope :interaction_count_lt, ->(count)do
    joins(:events).
      where(events: { event_type: 'message', is_for_bot: true }).
      group('bot_users.id').
      having('count(*) < ?', count)
  end

  scope :interaction_count_gt, ->(count)do
    joins(:events).
      where(events: { event_type: 'message', is_for_bot: true }).
      group('bot_users.id').
      having('count(*) > ?', count)
  end

  scope :interaction_count_betw, ->(min, max)do
    joins(:events).
      where(events: { event_type: 'message', is_for_bot: true }).
      group('bot_users.id').
      having('count(*) BETWEEN ? AND ?', min, max)
  end

  scope :interacted_at_betw, ->(min, max) do
    select("bot_users.*, COALESCE(events.last_event_at, NULL) AS last_event_at").
      joins(
        "LEFT JOIN (
          SELECT bot_user_id, MAX(events.created_at) AS last_event_at FROM events
          WHERE events.event_type = 'message' AND events.is_for_bot = 't' GROUP by bot_user_id
        ) events ON events.bot_user_id = bot_users.id").
      where('events.last_event_at BETWEEN ? AND ?', min, max).
      order("last_event_at DESC NULLS LAST").
      uniq
  end

  scope :interacted_at_ago_lt, ->(days_ago) do
    select("bot_users.*, COALESCE(events.last_event_at, NULL) AS last_event_at").
      joins(
        "LEFT JOIN (
          SELECT bot_user_id, MAX(events.created_at) AS last_event_at FROM events
          WHERE events.event_type = 'message' AND events.is_for_bot = 't' GROUP by bot_user_id
        ) events ON events.bot_user_id = bot_users.id").
      where('events.last_event_at > ?', days_ago).
      order("last_event_at DESC NULLS LAST").
      uniq
  end

  scope :interacted_at_ago_gt, ->(days_ago) do
    select("bot_users.*, COALESCE(events.last_event_at, NULL) AS last_event_at").
      joins(
        "LEFT JOIN (
          SELECT bot_user_id, MAX(events.created_at) AS last_event_at FROM events
          WHERE events.event_type = 'message' AND events.is_for_bot = 't' GROUP by bot_user_id
        ) events ON events.bot_user_id = bot_users.id").
      where('events.last_event_at < ?', days_ago).
      order("last_event_at DESC NULLS LAST").
      uniq
  end

  scope :user_signed_up_betw, ->(min, max) do
    where(created_at: min..max)
  end

  scope :order_by_last_event_at, ->(collection) do
    select("bot_users.*, COALESCE(events.created_at, null) AS last_event_at").
      joins(
        "LEFT JOIN (
            SELECT bot_user_id, MAX(events.created_at) AS created_at FROM events
            WHERE events.event_type = 'message' AND events.is_for_bot = 't' GROUP by bot_user_id
          ) events ON events.bot_user_id = bot_users.id").
      where(id: collection).
      order("last_event_at DESC NULLS LAST")
  end

  store_accessor :user_attributes, :nickname, :email, :full_name

  def self.with_bot_instances(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id)).joins(:bot_instance).
      where("bot_instances.created_at" => start_time..end_time)
  end

  def self.interacted_with(bot)
    joins(:events).
      where(events: { event_type: 'message', bot_instance: bot.instances.enabled, is_for_bot: true }).
      pluck(:id).
      uniq
  end
end
