module RubyNative
  module NativeDetection
    extend ActiveSupport::Concern

    included do
      helper_method :native_app?, :native_version, :native_platform if respond_to?(:helper_method)
    end

    def native_app?
      request.user_agent.to_s.include?("Ruby Native")
    end

    def native_version
      match = request.user_agent.to_s.match(/RubyNative\/([\d.]+)/)
      NativeVersion.new(match ? match[1] : "0")
    end

    # Returns "ios" or "android" for native requests, nil for web browsers.
    # Used by view helpers to pick the right icon from `icons: { ios:, android: }`.
    def native_platform
      ua = request.user_agent.to_s
      return "ios" if ua.include?("Ruby Native iOS")
      return "android" if ua.include?("Ruby Native Android")
      nil
    end
  end
end
