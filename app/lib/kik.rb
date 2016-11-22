require 'uri'

class Kik
  API_URL = ENV['KIK_API_URL'] || 'https://api.kik.com/v1'
  OK = 200

  def initialize(api_key, username)
    @token = api_key
    @username = username
  end

  def call(kik_api, method, params = {}, &block)
    params = params.select { |k,v| v.present? }
    auth_token = Base64.urlsafe_encode64("#{@username}:#{@token}")
    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360,
      headers: { 'Authorization': "Basic #{auth_token}" }
    }

    url = "#{API_URL}/#{kik_api}"

    if method.to_s.downcase == 'get'
      url = "#{url}?#{URI.encode_www_form(params)}"
    else
      opts[:body] = params.to_json
      opts[:headers].merge!({"Content-Type" => "application/json"})
    end

    if !block_given?
      connection = Excon.new(url, opts)
      response = connection.request(method: method)
      return JSON.parse(response.body).merge('status' => response.status)
    else
      opts[:response_block] = block
      connection = Excon.new(url, opts)
      connection.request(method: method)
    end
  end
end
