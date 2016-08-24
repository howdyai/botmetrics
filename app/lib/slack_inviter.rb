class SlackInviter
  def self.invite(email, name)
    params = {
      email: email,
      first_name: name
    }

    params.merge!(token: Settings.slack_inviter_token, t: Time.now.to_i)

    encoded_params = URI.encode_www_form(params)

    url = "https://botmetrics.slack.com/api/users.admin.invite?#{encoded_params}"
    connection = Excon.new(url, connect_timeout: 360,
                         omit_default_port: true,
                         idempotent: true,
                         retry_limit: 1,
                         read_timeout: 360)
    response = connection.request(method: :post)
    JSON.parse(response.body)
  end
end

