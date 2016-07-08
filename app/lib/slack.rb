require 'uri'

class Slack
  API_URL = ENV['SLACK_API_URL']

  def initialize(token)
    @token = token
  end

  def call(slack_api, method, params = {}, &block)
    params = params.select { |k,v| v.present? }
    params.merge!(token: @token)
    encoded_params = URI.encode_www_form(params)

    opts = {
      omit_default_port: true,
      idempotent: true,
      retry_limit: 6,
      read_timeout: 360,
      connect_timeout: 360
    }

    url = "#{API_URL}/#{slack_api}"

    if method.to_s.downcase == 'get'
      url = "#{url}?#{encoded_params}"
    else
      opts[:body] = URI.encode_www_form(params)
      opts[:headers] = { "Content-Type" => "application/x-www-form-urlencoded" }
    end


    if !block_given?
      connection = Excon.new(url, opts)
      response = connection.request(method: method)
      return JSON.parse(response.body)
    else
      opts[:response_block] = block
      connection = Excon.new(url, opts)
      connection.request(method: method)
    end
  end
end
