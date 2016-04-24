class RelaxService
  def self.handle(event)
    case event.type
    when 'team_joined'
      bi = find_bot_instance_from(event)
      return if bi.blank?
      ImportUsersForBotInstanceJob.perform_async(bi.id)
    when 'disable_bot'
      bi = find_bot_instance_from(event)
      return if bi.blank?

      if bi.state == 'enabled'
        bi.update_attribute(:state, 'disabled')
      end
    end
  end

  private
  def self.find_bot_instance_from(event)
    BotInstance.where("instance_attributes->>'team_id' = ? AND uid = ?", event.team_uid, event.namespace).first
  end
end
