class SetupBotJob < Job
  def perform(bot_instance_id, user_id)
    @instance = BotInstance.find(bot_instance_id)
    @user = User.find(user_id)

    case @instance.provider
    when 'slack' then setup_slack_bot!
    end
  end

  private

  def setup_slack_bot!
    slack = Slack.new(@instance.token)
    auth_info = slack.call('auth.test', :get)

    if auth_info['ok']
      @instance.update_attributes!(
        uid: auth_info['user_id'],
        state: 'enabled',
        instance_attributes: {
          team_id: auth_info['team_id'],
          team_name: auth_info['team'],
          team_url: auth_info['url']
        }
      )

      @instance.import_users!

      Relax::Bot.start!(@instance.instance_attributes['team_id'], @instance.token, namespace: @instance.uid)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: true}.to_json)
      TrackMixpanelEventJob.perform_async('Completed Bot Instance Creation', @user.id, state: 'enabled')

      Alerts::CreatedBotInstanceJob.perform_async(@instance.id, @user.id)
    else
      if auth_info['error'] == 'account_inactive'
        @instance.update_attribute(:state, 'disabled')
        @instance.events.create!(event_type: 'bot_disabled', provider: @instance.provider)
      end
      sleep(1)
      PusherJob.perform_async("setup-bot", "setup-bot-#{@instance.id}", {ok: false, error: auth_info['error']}.to_json)
      TrackMixpanelEventJob.perform_async('Completed Bot Instance Creation', @user.id, state: auth_info['error'])
    end
  end
end
