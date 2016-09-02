class FacebookApiMocks < Sinatra::Base
  post '/me/messages' do
    Rails.logger.warn "[FACEBOOK INTERCEPTED] POST#me/messages: #{(params).inspect}"

    [200, { 'recipient_id' => '123' }.to_json]
  end

  get '/*' do
    Rails.logger.warn "[SLACK INTERCEPTED] GET#wildcard: #{(params).inspect}"

    200
  end

  post '/*' do
    Rails.logger.warn "[SLACK INTERCEPTED] POST#wildcard: #{(params).inspect}"

    200
  end
end
