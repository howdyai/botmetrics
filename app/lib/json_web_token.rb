require 'jwt'

class JsonWebToken
  def self.encode(payload, expiration = 24.hours.from_now)
    payload = payload.dup
    payload['exp'] = expiration.to_i
    JWT.encode(payload, Settings.json_web_token_secret, 'HS256')
  end

  def self.decode(token)
    JWT.decode(token, Settings.json_web_token_secret, true, algorithm: 'HS256').first
  end
end
