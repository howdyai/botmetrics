class BotUser < ActiveRecord::Base
  belongs_to :bot_instance
  has_many :events

  validates_presence_of :uid, :membership_type, :bot_instance_id, :provider
  validates_uniqueness_of :uid, scope: :bot_instance_id
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  after_create :create_user_added_event

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

  scope :interacted_at_betw, ->(query, min, max) do
    where('last_interacted_with_bot_at BETWEEN ? AND ?', min, max).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :dashboard_betw, ->(query, min, max) do
    where(id: query.dashboard.events.where("events.created_at" => min..max).select(:bot_user_id))
  end

  scope :dashboard_gt, ->(query, days_ago) do
    where(id: query.dashboard.events.where("events.created_at < ?", days_ago).select(:bot_user_id))
  end

  scope :dashboard_lt, ->(query, days_ago) do
    where(id: query.dashboard.events.where("events.created_at > ?", days_ago).select(:bot_user_id))
  end

  scope :interacted_at_lt, ->(query, days_ago) do
    where('last_interacted_with_bot_at > ?', days_ago).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :interacted_at_gt, ->(query, days_ago) do
    where('last_interacted_with_bot_at < ?', days_ago).
    order("last_interacted_with_bot_at DESC NULLS LAST")
  end

  scope :user_signed_up_gt, ->(query, days_ago) do
    where('created_at < ?', days_ago)
  end

  scope :user_signed_up_lt, ->(query, days_ago) do
    where('created_at > ?', days_ago)
  end

  scope :user_signed_up_betw, ->(query, min, max) do
    where(created_at: min..max)
  end

  store_accessor :user_attributes, :nickname, :email, :full_name, :first_name, :last_name, :gender, :timezone, :ref

  def create_user_added_event
    begin
      self.bot_instance.events.create!(event_type: 'user-added', user: self, provider: self.provider, created_at: self.created_at)
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error "Could not create 'user-added' event for instance #{bot.uid} #{e.inspect}"
    end
  end

  def self.with_bot_instances(instances, bot, start_time, end_time)
    created_at = bot.provider == 'slack' ? "bot_instances.created_at" : "bot_users.created_at"

    where(bot_instance_id: instances.select(:id)).joins(:bot_instance).
      where(created_at => start_time..end_time)
  end

  def self.with_messages_to_bot(associated_bot_instances_ids)
    select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
    joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE events.event_type = 'message' AND events.is_for_bot = 't' GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
    where("bot_users.bot_instance_id IN (?)", associated_bot_instances_ids).
    order("last_event_at DESC NULLS LAST")
  end

  def self.with_messages_from_bot(associated_bot_instances_ids)
    select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
    joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE events.event_type = 'message' AND events.is_from_bot = 't' GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
    where("bot_users.bot_instance_id IN (?)", associated_bot_instances_ids).
    order("last_event_at DESC NULLS LAST")
  end

  def self.with_messaging_postbacks(associated_bot_instances_ids)
    select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
    joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE events.event_type = 'messaging_postbacks' GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
    where("bot_users.bot_instance_id IN (?)", associated_bot_instances_ids).
    order("last_event_at DESC NULLS LAST")
  end

  def self.with_message_subtype(associated_bot_instance_ids, type, provider)
    case provider
    when 'facebook'
      select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
      joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE events.event_type = 'message' " +
            "AND (event_attributes->>'attachments')::text IS NOT NULL AND (event_attributes->'attachments'->0->>'type')::text = '#{type}' " +
            "GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
      where("bot_users.bot_instance_id IN (?)", associated_bot_instance_ids).
      order("last_event_at DESC NULLS LAST")
    when 'kik'
      select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
      joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE events.event_type = 'message' " +
            "AND (event_attributes->>'sub_type')::text IS NOT NULL AND (event_attributes->>'sub_type')::text = '#{type}' " +
            "GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
      where("bot_users.bot_instance_id IN (?)", associated_bot_instance_ids).
      order("last_event_at DESC NULLS LAST")
    end
  end

  def self.with_events(associated_bot_user_ids, event_ids)
    events_condition = sanitize_sql_hash_for_conditions("events.id" => event_ids)

    select("bot_users.*, COALESCE(e.cnt, 0) AS events_count, e.c_at AS last_event_at").
    joins("LEFT JOIN (SELECT bot_user_id, COUNT(*) AS cnt, MAX(events.created_at) AS c_at FROM events WHERE #{events_condition} GROUP by bot_user_id) e ON e.bot_user_id = bot_users.id").
    where("bot_users.id IN (?)", associated_bot_user_ids).
    order("last_event_at DESC NULLS LAST")
  end

  def self.by_cohort(bot, start_time: 8.weeks.ago, end_time: Time.current, group_by: 'week')
    start_time = case group_by
                 when 'day' then start_time.beginning_of_day
                 when 'week' then start_time.beginning_of_week
                 when 'month' then start_time.beginning_of_month
                 end

    first_cohort_end = case group_by
    when 'day'
      start_time.end_of_day
    when 'week'
      start_time.end_of_week
    when 'month'
      start_time.end_of_month
    end

    end_time = case group_by
                 when 'day' then end_time.end_of_day
                 when 'week' then end_time.end_of_week
                 when 'month' then end_time.end_of_month
                 end
    # number of periods
    multiplier = case group_by
                 when 'day' then 1
                 when 'week' then 7
                 when 'month' then 30
                 end

    periods = ((end_time.to_i - start_time.to_i).to_f / (24 * 60 * 60 * multiplier)).ceil
    start_time_string = start_time.strftime('%Y-%m-%d %H:%M:%S.%N')
    first_cohort_end_string = first_cohort_end.strftime('%Y-%m-%d %H:%M:%S.%N')

    bot_instance_ids = bot.instances.pluck("bot_instances.id")
    first_cohort = sanitize_sql_for_conditions(["esub.created_at BETWEEN :start_time AND :end_time", start_time: start_time_string, end_time: first_cohort_end_string])
    users_condition = sanitize_sql_for_conditions(["bot_users.created_at BETWEEN :start_time AND :end_time AND bot_users.bot_instance_id IN (:bot_instances)", start_time: start_time_string, end_time: first_cohort_end_string, bot_instances: bot_instance_ids])
    bot_condition = sanitize_sql_for_conditions(["esub.bot_instance_id IN (?)", bot_instance_ids])

    counts = []
    periods.times { |i| counts << "COUNT(DISTINCT e#{i+1}.bot_user_id)" }

    sql = ["SELECT"]
    sql << counts.join(",")
    sql << "FROM"
    sql << """
    (
      SELECT * FROM events esub
      INNER JOIN bot_users ON bot_users.id = esub.bot_user_id
      WHERE #{first_cohort}
      AND #{bot_condition}
      AND #{users_condition}
      AND esub.is_for_bot = 't'
    ) e1
    """

    (2..periods).each do |i|
      next_start, next_end = case group_by
      when 'day'
        [(start_time + (i-1).send(group_by)), (start_time + (i-1).send(group_by)).end_of_day]
      when 'week'
        [(start_time + (i-1).send(group_by)), (start_time + (i-1).send(group_by)).end_of_week]
      when 'month'
        [(start_time + (i-1).send(group_by)), (start_time + (i-1).send(group_by)).end_of_month]
      end

      next_start = next_start.strftime('%Y-%m-%d %H:%M:%S.%N')
      next_end = next_end.strftime('%Y-%m-%d %H:%M:%S.%N')

      next_cohort = sanitize_sql_for_conditions(["esub.created_at BETWEEN :start_time AND :end_time", start_time: next_start, end_time: next_end])
      sql << """
        LEFT OUTER JOIN LATERAL (
         SELECT * FROM events esub
         WHERE esub.bot_user_id = e#{i-1}.bot_user_id
         AND #{next_cohort}
         AND #{bot_condition}
         AND esub.is_for_bot = 't'
         LIMIT 1
        ) e#{i}
        ON true
      """
    end

    records = Event.connection.execute(sql.join("\n"))
    records.values.first.map(&:to_i)
  end
end
