class RetentionController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @group_by = params[:group_by].presence || 'week'
    @start = params[:start].to_s.in_time_zone(current_user.timezone) || 4.weeks.ago
    @end = params[:end].to_s.in_time_zone(current_user.timezone) || Time.current

    @retention = retention_metrics
  end

  private
  def retention_metrics
    periods = 0
    retention = []

    case @group_by
    when 'day'
      periods = ((@end.to_i - @start.to_i).to_f / (24 * 60 * 60)).ceil
      (0...periods).each do |period|
        retention << BotUser.by_cohort(@bot, start_time: @start + period.days, end_time: @end, group_by: @group_by)
      end
    when 'week'
      periods = ((@end.to_i - @start.to_i).to_f / (24 * 60 * 60 * 7)).ceil
      (0...periods).each do |period|
        retention << BotUser.by_cohort(@bot, start_time: @start + period.weeks, end_time: @end, group_by: @group_by)
      end
    when 'month'
      periods = ((@end.to_i - @start.to_i).to_f / (24 * 60 * 60 * 30)).ceil
      (0...periods).each do |period|
        retention << BotUser.by_cohort(@bot, start_time: @start + period.months, end_time: @end, group_by: @group_by)
      end
    end

    retention
  end
end
