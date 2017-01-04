class Funnel < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of :bot_id, :user_id, :name, :dashboards
  validate :dashboards_cannot_be_less_than_one

  belongs_to :bot
  belongs_to :creator, class_name: 'User', foreign_key: 'user_id'

  def insights(step: 0, start_time: 1.week.ago, end_time: Time.current)
    result = {}

    dashboard1 = self.bot.dashboards.find_by(uid: self.dashboards[step].split(':').last)
    dashboard2 = self.bot.dashboards.find_by(uid: self.dashboards[step + 1].split(':').last)
    exclude_other_dashboards = self.bot.dashboards.where(dashboard_type: ['messages', 'message-from-bot']).pluck(:id)

    dashboard_ids = [dashboard1.id, dashboard2.id] + exclude_other_dashboards

    query = <<-SQL
SELECT rolledup_events.bot_user_id, rolledup_events.dashboard_id, SUM(rolledup_events.count)
FROM rolledup_events
LEFT OUTER JOIN LATERAL (
  SELECT e1.bot_user_id AS bot_user_id, dashboard_1_time, dashboard_2_time FROM
  (
    SELECT rolledup_events.bot_user_id, MIN(rolledup_events.created_at) AS dashboard_1_time
    FROM rolledup_events
    WHERE rolledup_events.dashboard_id = #{dashboard1.id}
    AND rolledup_events.created_at BETWEEN '#{start_time.to_s(:db)}' AND '#{end_time.to_s(:db)}'
    GROUP BY rolledup_events.bot_user_id
  ) e0 LEFT JOIN LATERAL (
    SELECT rolledup_events.bot_user_id, MIN(rolledup_events.created_at) AS dashboard_2_time
    FROM rolledup_events
    WHERE bot_user_id = e0.bot_user_id
    AND rolledup_events.dashboard_id = #{dashboard2.id}
    GROUP BY bot_user_id
    HAVING MIN(rolledup_events.created_at) BETWEEN dashboard_1_time AND dashboard_1_time + INTERVAL '1 WEEK'
  ) e1 ON TRUE
) re ON TRUE
WHERE rolledup_events.bot_user_id = re.bot_user_id
AND rolledup_events.created_at BETWEEN re.dashboard_1_time AND re.dashboard_2_time
GROUP BY rolledup_events.bot_user_id, rolledup_events.dashboard_id
SQL
    intermediate_result = Funnel.connection.execute(query).to_a

    intermediate_result.each do |row|
      dashboard_id = row['dashboard_id'].to_i
      bot_user_id = row['bot_user_id'].to_i
      sum = row['sum'].to_i

      sum = dashboard_ids.index(dashboard_id).present? ? 0 : sum
      result[bot_user_id] = result[bot_user_id].to_i + sum
    end

    group_by_count = {}
    result.each do |k,v|
      group_by_count[v] = group_by_count[v].to_i + 1
    end
    group_by_count = group_by_count.inject([]) do |arr, (k,v)|
      arr << [k,v]
    end.sort_by { |x| -x[1] }

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
  AND rolledup_events.created_at BETWEEN #{idx == 0 ? "'#{start_time.to_s(:db)}' AND '#{end_time.to_s(:db)}'" : "#{previous_dashboard_name}_time AND #{previous_dashboard_name}_time + INTERVAL '1 WEEK'"}
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
