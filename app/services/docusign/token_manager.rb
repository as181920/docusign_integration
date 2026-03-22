module Docusign
  class TokenManager
    class << self
      def current_access_token(connection)
        if connection.access_token.present? && connection.token_expires_at.present? && connection.token_expires_at > 2.minutes.from_now
          return connection.access_token
        end

        refresh_access_token(connection)
      end

      def refresh_access_token(connection)
        raise Docusign::ConfigurationError, "missing refresh_token" if connection.refresh_token.blank?

        token_info = OauthClient.new.refresh_token(refresh_token: connection.refresh_token)
        persist_token_info(connection, token_info)
        connection.access_token
      rescue StandardError => e
        connection.update(status: :expired)
        raise e
      end

      def persist_token_info(connection, token_info)
        expires_in = token_info["expires_in"].to_i

        connection.update!(
          access_token: token_info["access_token"],
          refresh_token: token_info["refresh_token"].presence || connection.refresh_token,
          token_expires_at: Time.current + expires_in.seconds,
          status: :active
        )
      end
    end
  end
end
