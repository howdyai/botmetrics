class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  helper_method :query_params

  def index
    @query_set = QuerySet.new(query_set_params)
    @query_set.queries.build(query_params) unless @query_set.queries.present?

    @tableized = FilterBotUsersService.new(@bot, @query_set, current_user.timezone).scope.page(params[:page])

    track_queries_to_mixpanel
  end

  private

    def query_set_params
      if params[:query_set].present?
        params.require(:query_set).permit(queries_attributes: [:id, :_destroy, :provider, :field, :method, :value, :min_value, :max_value] )
      else
        Hash.new
      end
    end

    def query_params
      { provider: @bot.provider }
    end

    def track_queries_to_mixpanel
      if query_attributes = query_set_params.presence
        TrackMixpanelEventJob.perform_async(
          'Viewed Analytics Index Page and Performed Queries',
          current_user.id,
          query_attributes: query_attributes
        )
      else
        TrackMixpanelEventJob.perform_async(
          'Viewed Analytics Index Page',
          current_user.id,
        )
      end
    end
end
