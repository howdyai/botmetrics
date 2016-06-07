# Return time zone names after given hour.
module ActiveSupport
  class TimeZone
    def self.zones_after(hour)
      all.select do |zone|
        Time.current.in_time_zone(zone).hour >= hour
      end.map(&:name)
    end
  end
end
