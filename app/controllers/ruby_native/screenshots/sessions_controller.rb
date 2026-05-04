module RubyNative
  module Screenshots
    # Validates the per-app screenshot key, signs in the configured screenshot
    # user, and sets a session-scoped cookie that the host app can use to
    # render deterministically (freeze timestamps, hide notifications, etc.).
    #
    # The key is sent in the `X-RubyNative-Screenshot-Key` header by the
    # WKWebView running on rubynative.com's screenshot infrastructure. A
    # `?key=` URL param is accepted as a fallback for environments where the
    # header is stripped by intermediate proxies; opt out by setting
    # `RubyNative.screenshot_allow_url_key = false` (default true).
    class SessionsController < ::ActionController::Base
      def show
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

        RubyNative.screenshot_sign_in.call(self)

        cookies[:_ruby_native_screenshot_session] = {
          value: "1",
          httponly: true,
          same_site: :lax
        }

        target = params[:return_to].presence || "/"
        target = "/" unless target.start_with?("/")
        redirect_to target, allow_other_host: false
      end

      private

      def valid_key?
        provided = request.headers["X-RubyNative-Screenshot-Key"].presence || params[:ruby_native_screenshot_key].presence
        return false unless provided
        ActiveSupport::SecurityUtils.secure_compare(provided.to_s, RubyNative.screenshot_key.to_s)
      end
    end
  end
end
