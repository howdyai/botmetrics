# frozen_string_literal: true

class GetStartEnd
  def initialize(start_time, end_time, user_time_zone = 'UTC')
    @start_time = start_time
    @end_time = end_time
    @user_time_zone = user_time_zone
  end

  def call
    start = start_time.to_s.in_time_zone(user_time_zone)
    start = (Time.current - 6.days).in_time_zone(user_time_zone) if start.blank?
    _end  = end_time.to_s.in_time_zone(user_time_zone)
    _end  = start + 6.days if _end.blank?

    start = start.beginning_of_day
    _end  = _end.end_of_day

    [start, _end]
  end

  private
  attr_reader :start_time, :end_time, :user_time_zone
end
