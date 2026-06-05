module RubyNative
  class AasaController < ::ActionController::Base
    def show
      RubyNative.load_config if Rails.env.development?

      bundle_id = RubyNative.config&.dig(:ios, :bundle_id)
      team_id = RubyNative.config&.dig(:ios, :team_id)
      return head :not_found unless bundle_id.present? && team_id.present?

      app_id = "#{team_id}.#{bundle_id}"
      response.set_header("Cache-Control", "no-cache")
      render json: {
        applinks: {
          details: [
            { appIDs: [ app_id ], components: oauth_exclusions + [ { "/": "*" } ] }
          ]
        },
        webcredentials: {
          apps: [ app_id ]
        }
      }
    end

    private

    # OAuth redirects must stay inside ASWebAuthenticationSession. With the
    # catch-all component alone, iOS treats the provider's redirect back to
    # the app's domain (e.g. /users/auth/google_oauth2/callback) as a
    # universal link, breaks out of the auth session, and native sign-in
    # fails. Excluding the configured OAuth paths keeps the OAuth round-trip
    # inside the session. The trailing `*` matches across `/`, so a start
    # path also covers its `/callback` child. Components are evaluated in
    # order and the first match wins, so exclusions go before the catch-all.
    # See https://github.com/ruby-native/gem/issues/59.
    def oauth_exclusions
      Array(RubyNative.config&.dig(:auth, :oauth_paths)).map do |path|
        { "/": "#{path}*", exclude: true }
      end
    end
  end
end
