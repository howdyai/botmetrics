class KikEventsService
  AVAILABLE_USER_FIELDS = %w(first_name last_name profile_pic_url profile_pic_last_modified)
  UPDATE_EVENTS         = { deliver: 'delivery-receipt', read: 'read-receipt' }

  def initialize(bot_id:, events:)
    @bot_id = bot_id
    @events = events
  end

  # We are using find_by here, because in Kik's case
  # only one instance of BotInstance will ever exist
  def bot_instance
    @bot_instance ||= BotInstance.find_by(bot_id: bot.id)
  end

  def bot
    @bot ||= Bot.find_by(uid: bot_id)
  end

  def create_events!
    serialized_params.each do |p|
      @params = p
      @event_type = params.dig(:data, :event_attributes, :sub_type)
      if UPDATE_EVENTS.has_value?(@event_type)
        update_message_events!
      else
        @bot_user = bot_instance.users.find_by(uid: bot_user_uid) || BotUser.new(uid: bot_user_uid)
        @bot_user.assign_attributes(bot_user_params) if @bot_user.new_record?

        create_message_events!
      end
    end
  end

  private
  attr_accessor :events, :bot_id, :params

  def update_message_events!
    query_params = [params.dig(:data, :event_attributes, :message_ids), false]
    case @event_type
    when UPDATE_EVENTS[:deliver]
      bot.events.where("event_attributes->>'id' IN (?) AND has_been_delivered = ?", *query_params).update_all(has_been_delivered: true)
    when UPDATE_EVENTS[:read]
      bot.events.where("event_attributes->>'id' IN (?) AND has_been_read = ?", *query_params).update_all(has_been_read: true)
    end
  end

  def create_message_events!
    ActiveRecord::Base.transaction do
      @bot_user.save!
      event = @bot_user.events.create!(event_params)

      if event.is_for_bot?
        @bot_user.increment!(:bot_interaction_count)
        @bot_user.update_attribute(:last_interacted_with_bot_at, event.created_at)
      end

      if (text = event.text).present?
        bot.dashboards.custom.enabled.each do |dashboard|
          r = Regexp.new(dashboard.regex, Regexp::IGNORECASE)
          dashboard.dashboard_events.create(event: event) if r.match(text)
        end
      end
    end
  end

  def serialized_params
    EventSerializer.new(:kik, events, bot_instance.uid).serialize
  end

  def event_params
    params.dig(:data).merge(bot_instance_id: bot_instance.id)
  end

  def fetch_user
    kik_client.call("user/#{bot_user_uid}",
                         :get).
                    stringify_keys
  end

  def bot_user_params
    user = fetch_user.symbolize_keys
    {
      user_attributes: {
        first_name: user[:firstName],
        last_name: user[:lastName],
        profile_pic_url: user[:profilePicUrl],
        profile_pic_last_modified: user[:profilePicLastModified]
      },
      bot_instance_id: bot_instance.id,
      provider: 'kik',
      membership_type: 'user'
    }
  end

  def kik_client
    Kik.new(bot_instance.token, bot_instance.uid)
  end


  def bot_user_uid
    params.dig(:recip_info, :from)
  end
end
