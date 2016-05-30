class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :init_fields_and_methods

  layout 'app'

  def index
    @query = Query.new
    @tableized = find_users.page(params[:page])
  end

  def query
    @query = Query.new(model_params)

    if @query.valid?
      @tableized = filter_by(find_users, method_type: model_params[:method]).page(params[:page])
      render 'index'
    else
      redirect_to bot_analytics_path, notice: 'Query is not valid, please re-try.'
    end
  end

  private

    def init_fields_and_methods
      @fields = [Field.new(:nickname, 'Nickname'), Field.new(:email, 'Email'), Field.new(:full_name, 'Name')]
      @methods = [SearchMethod.new(:equals_to, 'Equals to'), SearchMethod.new(:contains, 'Contains')]
    end

    def filter_by(collection, method_type: 'equals_to'.freeze)
      if method_type == 'contains'.freeze
        collection.where(
          "bot_users.user_attributes->>:field ILIKE :value",
          field: model_params[:field],
          value: "%#{model_params[:value]}%"
        )
      else
        collection.where(
          "bot_users.user_attributes->>:field = :value",
          field: model_params[:field],
          value: model_params[:value]
        )
      end
    end

    def find_users
      BotUser.where(bot_instance_id: @bot.instances.ids)
    end

    def model_params
      params.require(:query).permit(:field, :method, :value)
    end
end
