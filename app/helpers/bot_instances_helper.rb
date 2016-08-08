module BotInstancesHelper
  def new_instance_header(bot)
    case bot.provider
    when 'slack'
      bot.instances.legit.count == 0 ? "Let's setup the first instance of your Slack Bot" : "Setup Another Instance of your Slack Bot"
    when 'facebook'
      "Let's Setup Your Facebook Bot"
    end
  end

  def new_instance_token_label(bot)
    case bot.provider
    when 'slack'
      "Your Slack Bot's Token"
    when 'facebook'
      "Your Bot's Page Access Token"
    end
  end

  def new_instance_submit_text(bot)
    case bot.provider
    when 'slack'
      "Start Collecting Metrics"
    when 'facebook'
      "Setup Bot"
    end
  end

  def new_instance_disclaimer(bot)
    case bot.provider
    when 'facebook'
      "The page access token is available in 'Products' > 'Messenger' in your <a href='https://developers.facebook.com/' target='_blank'>app's dashboard</a>.".html_safe
    end
  end

  def new_instance_onboarding_image(bot)
    case bot.provider
    when 'facebook'
      image_tag('onboarding/facebook.png', class: 'img img-responsive img-onboarding img-thumbnail')
    end
  end

  def new_instance_tips(bot)
    case bot.provider
    when 'facebook'
      "<div class='onboarding-tips'>" +
        "<h4>Make sure you have the following options selected when setting up your webhook</h4>" +
        "<ul>" +
          "<li>message_deliveries</li>" +
          "<li>message_echoes</li>" +
          "<li>message_reads</li>" +
          "<li>messages</li>" +
          "<li>messaging_account_linking</li>" +
          "<li>messaging_optins</li>" +
          "<li>messaging_postbacks</li>" +
        "</ul>" +
      "</div>"
    end
  end

  def setting_up_header(bot)
    case bot.provider
    when 'slack'
      "Setting Up an Instance of '#{bot.name}'"
    when 'facebook'
      "Setting Up '#{bot.name}'"
    end
  end

  def setting_up_intro(bot)
    case bot.provider
    when 'slack'
      "We are setting up metrics collection for your bot..."
    when 'facebook'
      "We are setting up your bot..."
    end
  end
end
