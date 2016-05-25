module Alerts
  class DisabledBotInstanceJob < BaseJob
    def perform(bot_instance_id)
      AlertsMailer.disabled_bot_instance(bot_instance_id).deliver_later
    end
  end
end
