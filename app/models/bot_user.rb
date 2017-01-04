class BotUser < ActiveRecord::Base
  belongs_to :bot_instance
  has_many :events

  validates_presence_of :uid, :membership_type, :bot_instance_id, :provider
  validates_uniqueness_of :uid, scope: :bot_instance_id
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  after_create :create_user_added_event

  scope :followed_link_eq, ->(bot, value) do
    where(id: Event.where(bot_instance_id: bot.instances.select(:id), event_type: 'followed-link')
                   .where("event_attributes->>'url' = ?", value)
                   .select(:bot_user_id))
  end

  scope :followed_link_cont, ->(bot, value) do
    where(id: Event.where(bot_instance_id: bot.instances.select(:id), event_type: 'followed-link')
                   .where("event_attributes->>'url' ILIKE ?", "%#{value}%")
                   .select(:bot_user_id))
  end

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
    where(id: query.dashboard.events.where("rolledup_events.created_at" => min..max).select(:bot_user_id))
  end

  scope :dashboard_gt, ->(query, days_ago) do
    where(id: query.dashboard.events.where("rolledup_events.created_at < ?", days_ago).select(:bot_user_id))
  end

  scope :dashboard_lt, ->(query, days_ago) do
    where(id: query.dashboard.events.where("rolledup_events.created_at > ?", days_ago).select(:bot_user_id))
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

  attr_accessor  :step_count, :last_event

  store_accessor :user_attributes, :nickname, :email, :full_name, :first_name, :last_name, :gender, :timezone, :ref

  def create_user_added_event
    begin
      self.bot_instance.events.create!(event_type: 'user-added', user: self, provider: self.provider, created_at: self.created_at)
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error "Could not create 'user-added' event for instance #{bot.uid} #{e.inspect}"
    end
  end

  def profile_image_url
    self.user_attributes['profile_pic'] || self.user_attributes['profile_pic_url']
  end

  def self.with_events(events_relation)
    where("bot_users.id" => events_relation.select("rolledup_events.bot_user_id").group("rolledup_events.bot_user_id"))
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

    dashboard = bot.dashboards.find_by(dashboard_type: 'messages-to-bot')

    bot_instance_ids = bot.instances.pluck("bot_instances.id")
    first_cohort = sanitize_sql_for_conditions(["esub.created_at BETWEEN :start_time AND :end_time", start_time: start_time_string, end_time: first_cohort_end_string])
    users_condition = sanitize_sql_for_conditions(["bot_users.created_at BETWEEN :start_time AND :end_time AND bot_users.bot_instance_id IN (:bot_instances)", start_time: start_time_string, end_time: first_cohort_end_string, bot_instances: bot_instance_ids])
    bot_condition = sanitize_sql_for_conditions(["esub.dashboard_id IN (?)", dashboard.id])

    counts = []
    periods.times { |i| counts << "COUNT(DISTINCT e#{i+1}.bot_user_id)" }

    sql = ["SELECT"]
    sql << counts.join(",")
    sql << "FROM"
    sql << """
    (
      SELECT * FROM rolledup_events esub
      INNER JOIN bot_users ON bot_users.id = esub.bot_user_id
      WHERE #{first_cohort}
      AND #{bot_condition}
      AND #{users_condition}
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
         SELECT * FROM rolledup_events esub
         WHERE esub.bot_user_id = e#{i-1}.bot_user_id
         AND #{next_cohort}
         AND #{bot_condition}
         LIMIT 1
        ) e#{i}
        ON true
      """
    end

    records = Event.connection.execute(sql.join("\n"))
    records.values.first.map(&:to_i)
  end
end
