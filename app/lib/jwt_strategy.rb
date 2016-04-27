require 'json_web_token'

module Devise
  module Strategies
    class JwtStrategy < Base
      def valid?
        !request.headers['Authorization'].nil?
      end

      def authenticate!
        if claims && user = User.find_by_id(claims.fetch('user_id'))
          success!(user)
        else
          fail!
        end
      end

      def store?
        false
      end

      private
      def claims
        auth_header = request.headers['Authorization']
        token = auth_header.split(' ').last.to_s.strip

        token && JsonWebToken.decode(token)
      rescue => e
        nil
      end
    end
  end
end
