class Funnel < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of :bot_id, :user_id, :name, :dashboards
  validate :dashboards_cannot_be_less_than_one

  belongs_to :bot
  belongs_to :creator, class_name: 'User', foreign_key: 'user_id'

  def events(user, step: 0, start_time: 1.week.ago, end_time: Time.current, most_recent: false)
    dashboard1 = self.bot.dashboards.find_by(uid: self.dashboards[step].split(':').last)
    dashboard2 = self.bot.dashboards.find_by(uid: self.dashboards[step + 1].split(':').last)

    if dashboard1.custom?
      first_event = dashboard1.raw_events.where(created_at: start_time..end_time, bot_user_id: user.id).order('created_at ASC').first
    else
      first_event_conditions = {
                                 bot_user_id: user.id,
                                 event_type: dashboard1.event_type,
                                 created_at: start_time..end_time
                               }
      first_event_conditions.merge!(dashboard1.query_options)
      first_event = Event.where(first_event_conditions).order("created_at ASC").first
    end

    if dashboard2.custom?
      last_event = dashboard2.raw_events.where(created_at: first_event.created_at..first_event.created_at+1.week, bot_user_id: user.id).order('created_at ASC').first
    else
      last_event_conditions = {
                                bot_user_id: user.id,
                                event_type: dashboard2.event_type,
                                created_at: first_event.created_at..first_event.created_at + 1.week
                              }
      last_event_conditions.merge!(dashboard2.query_options)
      last_event = Event.where(last_event_conditions).order("created_at ASC").first
    end

    return [] if first_event.blank? || last_event.blank?

    if most_recent
      events_relation = Event.where("id > ? AND id < ?", first_event.id, last_event.id).
                              where(bot_user_id: user.id).
                              where(is_for_bot: true)
    else
      events_relation = Event.where("id >= ? AND id <= ?", first_event.id, last_event.id).
                              where(bot_user_id: user.id)
    end

    most_recent ? events_relation.order("id DESC").first : events_relation.order("id ASC")
  end

  def insights(step: 0, start_time: 1.week.ago, end_time: Time.current)
    result = {}

    dashboard1 = self.bot.dashboards.find_by(uid: self.dashboards[step].split(':').last)
    dashboard2 = self.bot.dashboards.find_by(uid: self.dashboards[step + 1].split(':').last)

    event_types_to_exclude = []
    event_types_to_exclude << dashboard1.event_type if dashboard1.event_type.present?
    event_types_to_exclude << dashboard2.event_type if dashboard2.event_type.present?

    query = <<-SQL
SELECT events.id, events.bot_user_id, events.event_type, events.is_for_bot, dashboard_events.dashboard_id
FROM events
LEFT OUTER JOIN LATERAL (
  SELECT e1.bot_user_id AS bot_user_id, dashboard_1_time FROM
  (
    SELECT rolledup_events.bot_user_id, MIN(rolledup_events.created_at) AS dashboard_1_time
    FROM rolledup_events
    WHERE rolledup_events.created_at BETWEEN '#{start_time.to_s(:db)}' AND '#{end_time.to_s(:db)}'
    AND rolledup_events.dashboard_id = #{dashboard1.id}
    GROUP BY rolledup_events.bot_user_id
  ) e0 INNER JOIN LATERAL (
    SELECT rolledup_events.bot_user_id, MIN(rolledup_events.created_at) AS dashboard_2_time
    FROM rolledup_events
    WHERE rolledup_events.created_at BETWEEN dashboard_1_time AND dashboard_1_time + INTERVAL '12 HOURS'
    AND rolledup_events.dashboard_id = #{dashboard2.id}
    AND bot_user_id = e0.bot_user_id
    GROUP BY bot_user_id
  ) e1 ON TRUE
) re ON TRUE
LEFT JOIN dashboard_events ON dashboard_events.event_id = events.id
WHERE events.bot_user_id = re.bot_user_id
AND events.created_at BETWEEN re.dashboard_1_time AND re.dashboard_1_time + INTERVAL '12 HOURS'
ORDER BY events.id ASC
SQL
    intermediate_result = Funnel.connection.execute(query).to_a

    start_counting, stop_counting = {}, {}

    intermediate_result.each do |row|
      event_id, event_type, bot_user_id, dashboard_id = row['id'], row['event_type'], row['bot_user_id'].to_i, row['dashboard_id'].to_i
      not_for_bot = row['is_for_bot'] == 'f'
      is_for_bot = !!not_for_bot

      start_counting[bot_user_id] = true if event_type == dashboard1.event_type || dashboard1.id == dashboard_id
      stop_counting[bot_user_id] = true if event_type == dashboard2.event_type || dashboard2.id == dashboard_id

      if start_counting[bot_user_id] && !!!stop_counting[bot_user_id]
        sum = not_for_bot ? 0 : 1
        result[bot_user_id] = result[bot_user_id].to_i + sum
      end
    end

    group_by_count = {}
    result.each do |k,v|
      group_by_count[v] = group_by_count[v].to_i + 1
    end
    group_by_count = group_by_count.inject([]) do |arr, (k,v)|
      arr << [k,v]
    end.sort_by { |x| -x[0] }

    {group_by_user: result, group_by_count: group_by_count}
  end

  def conversion(start_time: 1.week.ago, end_time: Time.current)
    queries = {}
    dashboards_map = {}

    self.dashboards.each_with_index do |dashboard_elem, idx|
      dashboard_uid = dashboard_elem.split(':').last
      dashboard = self.bot.dashboards.find_by(uid: dashboard_uid)
      dashboard_sql_name = dashboard.dashboard_type.underscore

      previous_dashboard_name = idx > 0 ? queries.keys[idx-1] : nil
      dashboards_map["dashboard_#{dashboard.uid}"] = dashboard

      queries["dashboard_#{dashboard.uid}"] = """
SELECT rolledup_events.bot_user_id, 1 as dashboard_#{dashboard.uid}, MIN(rolledup_events.created_at) AS dashboard_#{dashboard.uid}_time
  FROM rolledup_events
  WHERE rolledup_events.dashboard_id = #{dashboard.id}
  AND rolledup_events.created_at BETWEEN #{idx == 0 ? "'#{start_time.to_s(:db)}' AND '#{end_time.to_s(:db)}'" : "#{previous_dashboard_name}_time AND #{previous_dashboard_name}_time + INTERVAL '12 HOURS'"}
  #{idx > 0  ? "AND bot_user_id = e#{idx-1}.bot_user_id" : ""}
  GROUP BY rolledup_events.bot_user_id
  #{idx < self.dashboards.length - 1 ? ") e#{idx} #{idx > 0 ? "ON TRUE" : ''} LEFT JOIN LATERAL (" : ""}
      """
    end

    summation = queries.keys.map { |q| "SUM(#{q}) AS #{q}" }.join(", ")
    joins = queries.values.join("\n")
    query = "SELECT " +
            summation +
            " FROM (" +
            joins +
            " ) e#{queries.length - 1} ON true"

    results = Funnel.connection.execute(query)[0]
    results.inject({}) { |res, (k,v)| res[dashboards_map[k].funnel_name] = v.to_i; res }
  end

  def dashboards_cannot_be_less_than_one
    if self.dashboards.length < 2
      errors.add(:dashboards, "can't be less than 2 steps")
    end
  end
end
