class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  before_action :find_bot
  before_action :find_bot_instance

  def create
    message = Messages::Slack.new(model_params)

    if message_object = message.save_for(@bot_instance)
      SendMessageJob.perform_async(message_object.id)

      head :accepted
    else
      head :bad_request
    end
  end

  private

  def find_bot
    @bot = Bot.find(params[:bot_id])
  end

  def find_bot_instance
    @bot_instance = BotInstance.find_by_bot_and_team!(@bot, model_params[:team_id])
  end

  def model_params
    params.require(:message).permit(:team_id, :channel, :user, :text, :attachments)
  end
end
