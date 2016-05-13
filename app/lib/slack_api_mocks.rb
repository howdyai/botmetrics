class SlackApiMocks < Sinatra::Base
  post '/im.open' do
    Rails.logger.warn "[SLACK INTERCEPTED] POST#im.open: #{(params).inspect}"

    [200, { 'ok' => true, 'channel' => { 'id' => '123' } }.to_json]
  end

  post '/chat.postMessage' do
    Rails.logger.warn "[SLACK INTERCEPTED] POST#chat.postMessage: #{(params).inspect}"

    [200, { 'ok' => true }.to_json]
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
