# frozen_string_literal: true

class GetStartEnd
  def initialize(start_date, end_date, user_time_zone = 'UTC')
    @start_date = start_date
    @end_date = end_date
    @user_time_zone = user_time_zone
  end

  def call
    start = start_date.to_s.in_time_zone(user_time_zone)
    start = (Time.current - 6.days).in_time_zone(user_time_zone) if start.blank?
    _end  = end_date.to_s.in_time_zone(user_time_zone)
    _end  = start + 6.days if _end.blank?

    start = start.beginning_of_day
    _end  = _end.end_of_day

    [start, _end]
  end

  private

    attr_reader :start_date, :end_date, :user_time_zone
end
