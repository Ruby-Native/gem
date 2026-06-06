require "ruby_native/version"
require "ruby_native/helper"
require "ruby_native/native_version"
require "ruby_native/native_detection"
require "ruby_native/inertia_support"
require "ruby_native/oauth_middleware"
require "ruby_native/tunnel_cookie_middleware"
require "ruby_native/iap/event"
require "ruby_native/iap/verifiable"
require "ruby_native/iap/decodable"
require "ruby_native/iap/normalizable"
require "ruby_native/iap/apple_webhook_processor"
require "ruby_native/screenshots/sign_in_helper"
require "ruby_native/engine"

module RubyNative
  mattr_accessor :config
  mattr_accessor :subscription_callbacks, default: []

  # Screenshot configuration. Set via `RubyNative.configure` in an initializer.
  mattr_accessor :screenshot_key
  mattr_accessor :screenshot_sign_in

  def self.configure
    yield self
  end

  def self.on_subscription_change(&block)
    subscription_callbacks << block
  end

  def self.fire_subscription_callbacks(event)
    subscription_callbacks.each { |cb| cb.call(event) }
  end

  def self.load_config
    path = Rails.root.join("config", "ruby_native.yml")
    return unless path.exist?

    self.config = YAML.load_file(path).deep_symbolize_keys
    self.config[:app] ||= {}
    self.config[:app][:entry_path] ||= self.config.dig(:tabs, 0, :path) || "/"
    self.config[:auth] ||= {}
    normalize_oauth_paths
    backfill_tab_icons
  end

  # Mirrors per-platform `icons:` into the legacy flat `icon:` field so native
  # binaries that only read `tab.icon` keep rendering an icon. Explicit `icon:`
  # wins; otherwise falls back to `icons.ios`, then `icons.android`.
  def self.backfill_tab_icons
    Array(self.config[:tabs]).each do |tab|
      next unless tab.is_a?(Hash)

      icons = tab[:icons]
      next unless icons.is_a?(Hash)

      tab[:icon] ||= icons[:ios] || icons[:android]
    end
  end

  # `auth.oauth_paths` must list only OAuth authorize paths, never their
  # callbacks. The native app treats every listed path as a sign-in trigger and
  # derives the provider from the last path segment, so a callback entry like
  # "/auth/google/callback" would launch a bogus flow for a provider named
  # "callback" and send sign-in into a loop. The callback round-trip is handled
  # automatically by OAuthMiddleware's tracking cookie, so it never needs
  # listing. Drop any entry that is the "/callback" child of another listed
  # path and warn, so a copied-in callback can't break native sign-in.
  def self.normalize_oauth_paths
    paths = Array(self.config.dig(:auth, :oauth_paths))
    callbacks = paths.select { |path| paths.any? { |start| path == "#{start}/callback" } }
    return if callbacks.empty?

    Rails.logger.warn(
      "[RubyNative] Ignoring OAuth callback path(s) in config/ruby_native.yml " \
      "(#{callbacks.join(", ")}). List only the authorize path; callbacks are handled automatically."
    )
    self.config[:auth][:oauth_paths] = paths - callbacks
  end
end
