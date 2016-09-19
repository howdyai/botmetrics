class ApplicationMailer < ActionMailer::Base
  default from: 'Botmetrics <alerts@getbotmetrics.com>'
  default_url_options[:host] = Setting.hostname
end
