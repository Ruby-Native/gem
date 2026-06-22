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
    backfill_error_icons
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

  # Mirrors `backfill_tab_icons` for the error screen: fills a state's flat
  # `icon` from its per-platform `icons` (ios first, then android), so the iOS
  # app, which reads only the flat `icon`, still renders one. An explicit
  # `icon:` wins.
  def self.backfill_error_icons
    errors = self.config[:errors]
    return unless errors.is_a?(Hash)

    ERROR_SCREEN_STATES.each do |state|
      state_config = errors[state]
      next unless state_config.is_a?(Hash)

      icons = state_config[:icons]
      next unless icons.is_a?(Hash)

      state_config[:icon] ||= icons[:ios] || icons[:android]
    end
  end

  # The native fallback screen has two states: `offline` (no connectivity) and
  # `generic` (any other load failure). Each can carry a per-platform icon and
  # localized copy.
  ERROR_SCREEN_STATES = %i[offline generic].freeze
  ERROR_SCREEN_COPY_KEYS = %i[title message].freeze

  # The JSON served at GET /native/config. Identical to `config`, except the
  # `errors` block is enriched: per-state icons from config/ruby_native.yml are
  # merged with localized title/message pulled from the host app's I18n
  # (`ruby_native.errors.<state>.<key>`), one entry per available locale. Only
  # values the developer actually provided are emitted; the native apps fall
  # back to bundled English copy for anything missing. Built on a deep copy so
  # the in-memory `config` the server reads for view helpers is never mutated.
  def self.config_as_json
    return config if config.nil?

    payload = config.deep_dup
    errors = error_screen_config(payload[:errors])
    if errors.empty?
      payload.delete(:errors)
    else
      payload[:errors] = errors
    end
    payload
  end

  # Merges per-state error-screen icons (from YAML) with localized copy (from
  # I18n) into the shape the native apps decode. Omits any state with neither an
  # icon nor copy, so an untouched app sends no `errors` block at all.
  def self.error_screen_config(yaml_errors)
    config = ERROR_SCREEN_STATES.each_with_object({}) do |state, result|
      entry = {}
      state_config = yaml_errors[state] if yaml_errors.is_a?(Hash)
      if state_config.is_a?(Hash)
        entry[:icon] = state_config[:icon] if state_config[:icon]
        entry[:icons] = state_config[:icons] if state_config[:icons]
      end
      ERROR_SCREEN_COPY_KEYS.each do |key|
        translations = error_screen_translations("#{state}.#{key}")
        entry[key] = translations unless translations.empty?
      end
      result[state] = entry unless entry.empty?
    end

    # The Retry button label is shared by both states, so it sits at the top of
    # the block rather than under a state.
    retry_label = error_screen_translations("retry")
    config[:retry] = retry_label unless retry_label.empty?
    config
  end

  # Reads `ruby_native.errors.<subkey>` for every available locale, keeping only
  # the locales the developer actually translated. Copy lives in the host app's
  # own locale files; the gem ships none.
  def self.error_screen_translations(subkey)
    I18n.available_locales.each_with_object({}) do |locale, result|
      value = I18n.t("ruby_native.errors.#{subkey}", locale: locale, default: nil)
      result[locale] = value unless value.nil?
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
