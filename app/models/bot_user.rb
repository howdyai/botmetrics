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

  scope :interaction_count_eq, ->(bot_instances, count)do
    joins(:events).
      where(events: { event_type: 'message', bot_instance: bot_instances, is_for_bot: true }).
      group('bot_users.id').
      having('count(*) = ?', count)
  end

  scope :interaction_count_betw, ->(bot_instances, min, max)do
    joins(:events).
      where(events: { event_type: 'message', bot_instance: bot_instances, is_for_bot: true }).
      group('bot_users.id').
      having('count(*) BETWEEN ? AND ?', min, max)
  end

  scope :interacted_at_betw, ->(bot_instances, min, max) do
    joins(:events).
      where(events: { event_type: 'message', bot_instance: bot_instances, is_for_bot: true }).
      where('events.created_at BETWEEN ? AND ?', min, max).
      uniq
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
