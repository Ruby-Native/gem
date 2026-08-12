module RubyNative
  module NativeDetection
    extend ActiveSupport::Concern

    # Matches "Ruby Native iOS/5.2/35 iOS/26.5.2 RubyNative/0.12.5". The build and
    # OS groups are optional: apps built before the UA carried them send only
    # "Ruby Native iOS/5.2", and the optional group keeps the OS capture from
    # swallowing that app version.
    SIGNATURE = %r{Ruby Native (?:iOS|Android)/([\d.]+)(?:/([\d.]+) (?:iOS|Android)/([\d.]+))?}

    included do
      if respond_to?(:helper_method)
        helper_method :native_app?, :native_version, :native_platform,
          :native_app_version, :native_app_build, :native_os_version
      end
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

    # The app's marketing version, like "5.2". Nil for web browsers.
    def native_app_version
      request.user_agent.to_s[SIGNATURE, 1]
    end

    # The app's build number (CFBundleVersion / versionCode), like "35". Nil for
    # web browsers and apps built before the User-Agent carried it.
    def native_app_build
      request.user_agent.to_s[SIGNATURE, 2]
    end

    # The device's OS version, like "26.5.2". Nil for web browsers and apps built
    # before the User-Agent carried it.
    def native_os_version
      request.user_agent.to_s[SIGNATURE, 3]
    end
  end
end
