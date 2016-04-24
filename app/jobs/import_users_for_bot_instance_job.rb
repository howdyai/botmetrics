class ImportUsersForBotInstanceJob < Job
  def perform(bot_instance_id)
    bi = BotInstance.find(bot_instance_id)
    bi.import_users!
  end
end
