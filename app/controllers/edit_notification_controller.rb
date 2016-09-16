class EditNotificationController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot
  before_action :find_notification
  before_action :valid_notification?

  before_action :reset_session!, only: [:step_1]
  before_action :validate_step_1!, only: [:step_2]
  before_action :validate_step_2!, only: [:step_3]

  helper_method :default_query

  layout 'app'

  def step_1
    @query_set =
      QuerySetBuilder.new(
        bot: @bot,
        instances_scope: :enabled,
        time_zone: current_user.timezone,
        default: default_query,
        params: params,
        session: session[:edit_notification_query_set] || @notification.query_set.to_form_params
      ).query_set

    @tableized = FilterBotUsersService.new(@query_set).scope.page(params[:page])

    session[:edit_notification_query_set] = @query_set.to_form_params
  end

  def step_2
    @notification.assign_attributes(model_params)
  end

  def step_3
    @notification.assign_attributes(model_params)
  end

  def update
    @query_set = QuerySetBuilder.new(session: session[:edit_notification_query_set]).query_set
    @notification.assign_attributes(model_params.merge(query_set: @query_set))

    if @query_set.present? && @query_set.valid? && @notification.save(context: :schedule)
      session.delete(:edit_notification_query_set)

      send_or_queue_and_redirect
    else

      redirect_to step_3_bot_edit_notification_path(@bot, @notification, params.slice(:notification))
    end
  end

  private
  def find_notification
    @notification = @bot.notifications.find_by!(uid: params[:id])
  end

  def valid_notification?
    raise ActiveRecord::RecordNotFound if @notification.sent?
  end

  def default_query
    { provider: @bot.provider, field: :interaction_count, method: :greater_than, value: 1 }
  end

  def model_params
    if params[:notification].present?
      params.require(:notification).permit(:content, :scheduled_at, :recurring)
    else
      Hash.new
    end
  end

  def reset_session!
    if params[:reset].present? || action_name == 'step_1'
      session.delete(:edit_notification_query_set)
    end
  end

  def validate_step_1!
    if session[:edit_notification_query_set].blank?
      redirect_to step_1_bot_edit_notification_path(@bot, @notification) and return
    end
  end

  def validate_step_2!
    if params.dig(:notification, :content).blank?
      redirect_to step_2_bot_edit_notification_path(@bot, @notification, params.slice(:notification)) and return
    end
  end

  def send_or_queue_and_redirect
    if @notification.send_immediately?
      SendNotificationJob.perform_async(@notification.id)

      redirect_to [@bot, @notification]
    else
      EnqueueNotificationJob.perform_async(@notification.id)

      redirect_to bot_notifications_path(@bot), notice: 'This notification has been queued.'
    end
  end
end
