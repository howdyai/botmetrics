class NearestTime
  def self.round(current_time, granularity=30.minutes)
    Time.at((current_time.to_i/granularity).round * granularity).utc
  end
end
