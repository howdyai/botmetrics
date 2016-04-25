class RelaxService
  def self.handle(event)
    case event.type
    when 'team_joined'
      bi = find_bot_instance_from(event)
      return if bi.blank?
      ImportUsersForBotInstanceJob.perform_async(bi.id)
      bi.events.create!(event_type: 'user_added', provider: bi.provider)
    when 'disable_bot'
      bi = find_bot_instance_from(event)
      return if bi.blank?

      if bi.state == 'enabled'
        bi.update_attribute(:state, 'disabled')
        bi.events.create!(event_type: 'bot_disabled', provider: bi.provider)
      end
    end
  end

  private
  def self.find_bot_instance_from(event)
    BotInstance.where("instance_attributes->>'team_id' = ? AND uid = ?", event.team_uid, event.namespace).first
  end
end
