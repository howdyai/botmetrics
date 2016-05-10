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
    when 'message_new'
      bi = find_bot_instance_from(event)
      if bi.blank?
        Rails.logger.error "couldn't find bot instance for #{event.inspect}"
      end
      user = find_bot_user_from(bi, event)
      if user.blank?
        Rails.logger.error "couldn't find bot instance for #{event.inspect}"
      end

      bi.events.create!(
        user: user,
        event_attributes: {
          channel: event.channel_uid,
          timestamp: event.timestamp
        },
        is_for_bot: is_for_bot?(event),
        is_im: event.im,
        is_from_bot: event.relax_bot_uid == event.user_uid,
        provider: bi.provider,
        event_type: 'message'
      )
    when 'reaction_added'
      bi = find_bot_instance_from(event)
      return if bi.blank?
      user = find_bot_user_from(bi, event)
      return if user.blank?

      event = bi.events.create(
        user: user,
        event_attributes: {
          channel: event.channel_uid,
          timestamp: event.timestamp,
          reaction: event.text
        },
        is_for_bot: is_for_bot?(event),
        is_im: event.im,
        is_from_bot: event.relax_bot_uid == event.user_uid,
        provider: bi.provider,
        event_type: 'message_reaction'
      )

      unless event.persisted?
        Rails.logger.error "Couldn't save event: #{event.inspect}"
      end
    end
  end

  private
  def self.find_bot_user_from(bi, event)
    user = bi.users.find_by(uid: event.user_uid)
    # if user is blank, then import users and try again before bailing
    if user.blank?
      bi.import_users!
      user = bi.users.find_by(uid: event.user_uid)
    end

    user
  end

  def self.is_for_bot?(event)
    if event.relax_bot_uid == event.user_uid
      false
    else
      event.im || event.text.match(/<?@#{event.relax_bot_uid}[^>]?>?/).present?
    end
  end

  def self.find_bot_instance_from(event)
    BotInstance.where("instance_attributes->>'team_id' = ? AND uid = ?", event.team_uid, event.namespace).first
  end
end
