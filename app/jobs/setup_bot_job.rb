class SetupBotJob < Job
  def perform(bot_instance_id, user_id)
    @instance = BotInstance.find(bot_instance_id)
    @user = User.find(user_id)

    send("setup_#{@instance.provider}_bot!")
  end

  private

  def setup_slack_bot!
    slack = Slack.new(@instance.token)
    auth_info = slack.call('auth.test', :get)

    if auth_info['ok']
      bi = @instance.bot.instances.where("uid = ? AND instance_attributes->>'team_id' = ? AND state = ?", auth_info['user_id'], auth_info['team_id'], 'enabled').first
      token = @instance.token

      # If there is an existing bot instance with the same uid/team_id, then delete the current one and update attributes
      # on the old one
      if bi.present?
        @instance.destroy
        @instance = bi
      end

      @instance.update_attributes!(
        uid: auth_info['user_id'],
        state: 'enabled',
        token: token,
        instance_attributes: {
          team_id: auth_info['team_id'],
          team_name: auth_info['team'],
          team_url: auth_info['url']
        }
      )

      @instance.import_users!

      Relax::Bot.start!(@instance.instance_attributes['team_id'], @instance.token, namespace: @instance.uid)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: true}.to_json)

      Alerts::CreatedBotInstanceJob.perform_async(@instance.id, @user.id)
      NotifyAdminOnSlackJob.perform_async(@user.id, title: "New Team Signed Up for #{@instance.bot.name}", team: @instance.team_name, bot: @instance.bot.name, members: @instance.users.count)
    else
      if auth_info['error'] == 'account_inactive'
        @instance.update_attribute(:state, 'disabled')
        @instance.events.create!(event_type: 'bot_disabled', provider: @instance.provider)
      end
      sleep(1)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: false, error: auth_info['error']}.to_json)
    end

    begin
      @instance.events.create!(event_type: 'bot-installed', provider: @instance.provider, created_at: @instance.created_at)
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error "Could not create event 'bot-installed' for instance #{bot.uid} #{e.inspect}"
    end
  end

  def setup_facebook_bot!
    facebook = Facebook.new(@instance.token)
    auth_info = facebook.call('me', :get)

    if auth_info['status'] == Facebook::OK
      @instance.update_attributes!(
        uid: auth_info['id'],
        state: 'enabled',
        token: @instance.token,
        instance_attributes: {
          name: auth_info['name']
        }
      )

      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: true}.to_json)
    else
      error_msg = auth_info.dig('error', 'message')

      if error_msg =~ Regexp.new(Facebook::DELETED, Regexp::IGNORECASE) ||
        error_msg =~ Regexp.new(Facebook::INVALID_OAUTH_TOKEN, Regexp::IGNORECASE)
        @instance.update_attribute(:state, 'disabled')
        # @instance.events.create!(event_type: 'bot_disabled', provider: @instance.provider)
      end
      sleep(1)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: false, error: error_msg}.to_json)
    end
  end

  def setup_kik_bot!
    kik = Kik.new(@instance.token, @instance.uid)
    auth_info = kik.call('config', :get)

    if auth_info['status'] == Kik::OK
      @instance.update_attributes!(
        uid: @instance.uid,
        state: 'enabled',
        token: @instance.token,
        instance_attributes: auth_info.except('status')
      )

      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", { ok: true }.to_json)
      Alerts::CreatedBotInstanceJob.perform_async(@instance.id, @user.id)
    else
      error_msg = auth_info['error']
      @instance.update_attributes!(state: 'disabled', uid: nil)
      # @instance.events.create!(event_type: 'bot_disabled', provider: @instance.provider)
      sleep(1)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", { ok: false, error: error_msg }.to_json)
    end
  end
end
