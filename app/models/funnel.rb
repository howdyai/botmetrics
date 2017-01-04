class Funnel < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of :bot_id, :user_id, :name, :dashboards
  validate :dashboards_cannot_be_less_than_one

  belongs_to :bot
  belongs_to :creator, class_name: 'User', foreign_key: 'user_id'

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
