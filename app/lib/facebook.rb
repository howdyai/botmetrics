require 'uri'

class Facebook
  API_URL = ENV['FACEBOOK_API_URL'] || 'https://graph.facebook.com/v2.6'
  OK = 200
  DELETED = 'deleted'
  INVALID_OAUTH_TOKEN = 'Invalid OAuth Access Token'

  def initialize(token)
    @token = token
  end

  def call(facebook_api, method, params = {}, &block)
    params = params.select { |k,v| v.present? }

    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360
    }

    url = "#{API_URL}/#{facebook_api}?access_token=#{@token}"

    if method.to_s.downcase == 'get'
      url = "#{url}&#{URI.encode_www_form(params)}"
    else
      opts[:body] = params.to_json
      opts[:headers] = { "Content-Type" => "application/json" }
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
