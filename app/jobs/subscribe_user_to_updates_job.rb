class SubscribeUserToUpdatesJob < Job
  API_URL = "https://phonehome.getbotmetrics.com"

  def perform(user_id)
    user = User.find(user_id)
    encoded_params = {
      install: {
        email: user.email,
        full_name: user.full_name
      }
    }.to_query

    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360
    }

    url = "#{API_URL}/installs"

    opts[:body] = encoded_params
    opts[:headers] = { "Content-Type" => "application/x-www-form-urlencoded" }

    connection = Excon.new(url, opts)
    response = connection.request(method: :post)
    Rails.logger.warn "[SubscribeUserToUpdatesJob] Received Status Code: #{response.status}"
    response.status
  end
end
