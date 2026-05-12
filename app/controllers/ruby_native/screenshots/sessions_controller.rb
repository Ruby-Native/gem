module RubyNative
  module Screenshots
    # Validates the per-app screenshot key, signs in the configured screenshot
    # user, and sets a session-scoped cookie that the host app can use to
    # render deterministically (freeze timestamps, hide notifications, etc.).
    #
    # The key is accepted via the `X-RubyNative-Screenshot-Key` header or the
    # `?ruby_native_screenshot_key=` URL parameter. WKWebView drops custom
    # headers across redirect chains in some iOS versions, so the URL-param
    # fallback is the primary path used by Ruby Native's screenshot pipeline.
    class SessionsController < ::ActionController::Base
      def show
        # Defense in depth: prevent the URL (which carries the key as a query
        # param on the way in) from leaking via the Referer header to anything
        # the redirect target loads.
        response.headers["Referrer-Policy"] = "no-referrer"

        unless RubyNative.screenshot_key.present? && RubyNative.screenshot_sign_in.present?
          Rails.logger.info { "[RubyNative] /native/screenshots/session called but screenshot config is not set" }
          head :not_found
          return
        end

        unless valid_key?
          Rails.logger.info { "[RubyNative] /native/screenshots/session rejected: invalid key" }
          head :unauthorized
          return
        end

        RubyNative.screenshot_sign_in.call(SignInHelper.new(self))

        cookies[:_ruby_native_screenshot_session] = {
          value: "1",
          httponly: true,
          secure: request.ssl?,
          same_site: :lax
        }

        redirect_to safe_return_to, allow_other_host: false
      end

      private

      def valid_key?
        provided = request.headers["X-RubyNative-Screenshot-Key"].presence || params[:ruby_native_screenshot_key].presence
        return false unless provided
        ActiveSupport::SecurityUtils.secure_compare(provided.to_s, RubyNative.screenshot_key.to_s)
      end

      def safe_return_to
        target = params[:return_to].to_s
        return "/" if target.empty?
        # Reject anything that isn't a single-leading-slash same-host path.
        # `//evil.com` and `/\evil.com` would be treated as protocol-relative
        # or backslash-confusing inputs by some browsers.
        return "/" if target.start_with?("//", "/\\")
        return "/" unless target.start_with?("/")
        target
      end
    end
  end
end
