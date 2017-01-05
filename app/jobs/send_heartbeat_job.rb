class SendHeartbeatJob < Job
  API_URL = "https://phonehome.getbotmetrics.com"

  def perform
    user = User.order("id ASC").first
    return if user.blank?

    encoded_params = {
      install: {
        email: user.email,
        full_name: user.full_name,
        events: RolledupEvent.sum(:count).to_i,
        users: BotUser.count
      }
    }.to_query

    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360
    }

    url = "#{API_URL}/installs/heartbeat"

    opts[:body] = encoded_params
    opts[:headers] = { "Content-Type" => "application/x-www-form-urlencoded" }

    connection = Excon.new(url, opts)
    response = connection.request(method: :post)
    Rails.logger.warn "[SendHeartbeatJob] Received Status Code: #{response.status}"
    response.status
  end
end

