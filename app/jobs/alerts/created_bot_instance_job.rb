module Alerts
  class CreatedBotInstanceJob < BaseJob
    def perform(bot_instance_id, user_id)
      AlertsMailer.created_bot_instance(bot_instance_id, user_id).deliver_later
    end
  end
end
