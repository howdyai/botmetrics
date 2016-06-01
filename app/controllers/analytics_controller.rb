class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  def index
    @query_set = QuerySet.new(model_params)
    @query_set.queries.build unless @query_set.queries.present?

    @tableized = FilterBotUsersService.new(@bot, @query_set).scope.page(params[:page])
  end

  private

    def model_params
      if params[:query_set].present?
        params.require(:query_set).permit(queries_attributes: [:id, :_destroy, :field, :method, :value] )
      else
        Hash.new
      end
    end
end
