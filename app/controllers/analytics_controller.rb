class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @query_set = QuerySet.new(model_params)
    @query_set.queries.build unless @query_set.queries.present?

    @tableized = FilterBotUsersService.new(@bot, @query_set).scope.page(params[:page])
    track_queries_to_mixpanel
  end

  private

    def model_params
      if params[:query_set].present?
        params.require(:query_set).permit(queries_attributes: [:id, :_destroy, :field, :method, :value, :min_value, :max_value] )
      else
        Hash.new
      end
    end

    def track_queries_to_mixpanel
      if query_attributes = model_params.presence
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
