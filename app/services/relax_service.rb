class RelaxService
  def self.handle(event)
    bi = find_bot_instance_from(event)
    if bi.blank?
      Rails.logger.error "couldn't find bot instance for #{event.inspect}"
      return
    end

    case event.type
    when 'team_joined'
      ImportUsersForBotInstanceJob.perform_async(bi.id)
      bi.events.create!(event_type: 'user_added', provider: bi.provider)
    when 'disable_bot'
      if bi.state == 'enabled'
        bi.update_attribute(:state, 'disabled')
        bi.events.create!(event_type: 'bot_disabled', provider: bi.provider)

        Alerts::DisabledBotInstanceJob.perform_async(bi.id)
      end
    when 'message_new'
      user = find_bot_user_from(bi, event)
      if user.blank?
        Rails.logger.error "couldn't find bot instance for #{event.inspect}"
      end

      e = bi.events.create(
        user: user,
        event_attributes: {
          channel: event.channel_uid,
          timestamp: event.timestamp
        },
        is_for_bot: is_for_bot?(event),
        is_im: event.im,
        is_from_bot: event.relax_bot_uid == event.user_uid,
        text: is_for_bot?(event) || event.relax_bot_uid == event.user_uid ? event.text : nil,
        provider: bi.provider,
        event_type: 'message',
        created_at: Time.at(event.timestamp.to_f),
        has_been_read: true,
        has_been_delivered: true
      )

      if e.persisted? && e.is_for_bot?
        user.increment!(:bot_interaction_count)
        user.update_attribute(:last_interacted_with_bot_at, e.created_at)
      end
    when 'reaction_added'
      user = find_bot_user_from(bi, event)
      return if user.blank?

      e = bi.events.create(
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
        event_type: 'message_reaction',
        created_at: Time.at(event.timestamp.to_f),
        has_been_read: true,
        has_been_delivered: true
      )

      if !e.persisted?
        Rails.logger.error "[RelaxService] Couldn't persist event #{event.to_hash}"
      end
    end

    if bi.bot.webhook_url.present?
      SendEventToWebhookJob.perform_async(bi.bot_id, event.to_json)
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
