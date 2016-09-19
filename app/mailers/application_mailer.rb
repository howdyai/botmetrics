class ApplicationMailer < ActionMailer::Base
  default from: 'hello@getbotmetrics.com'
  default_url_options[:host] = Setting.hostname
end
