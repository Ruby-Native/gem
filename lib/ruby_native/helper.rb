module RubyNative
  module Helper
    # True when the current request is part of a Ruby Native screenshot run.
    # Use this to render deterministically: freeze relative timestamps, hide
    # push banners, suppress ads, disable A/B variants, skip notifications.
    #
    #   <% if ruby_native_screenshot_session? %>
    #     Stamped 2 days ago
    #   <% else %>
    #     <%= time_ago_in_words(stamp.created_at) %>
    #   <% end %>
    def ruby_native_screenshot_session?
      cookies[:_ruby_native_screenshot_session] == "1"
    end

    def native_tabs_tag(enabled: true)
      return "".html_safe unless enabled
      tag.div(data: { native_tabs: true }, hidden: true)
    end

    def native_form_tag
      tag.div(data: { native_form: true }, hidden: true)
    end

    def native_push_tag
      tag.div(data: { native_push: true }, hidden: true)
    end

    def native_back_button_tag(text = nil, **options)
      options[:class] = [options[:class], "native-back-button"].compact.join(" ")
      default_content = tag.svg(
        tag.path(d: "M15.75 19.5L8.25 12l7.5-7.5", stroke_linecap: "round", stroke_linejoin: "round"),
        width: 24, height: 24, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: 2.5
      )
      tag.button(text || default_content, onclick: "RubyNative.postMessage({action: 'back'})", **options)
    end

    # Renders a button that opens the native barcode scanner. On a successful
    # scan the value fills `target` (a CSS selector) and the page receives a
    # `ruby-native:scan` CustomEvent (override the name with `event:`). Set
    # `submit: true` to submit the filled field's form after scanning. Narrow the
    # accepted codes with `formats:` (neutral names, e.g. "ean13,upce"); omit it
    # for a sane default. Renders a plain button on the web (no-op until opened in
    # the app); wrap in `native_app?` if it should be hidden there.
    #
    #   <%= native_scan_button_tag "Scan", target: "#isbn" %>
    #
    # The scanner needs a camera usage description set in your Ruby Native app
    # settings, or scanning is unavailable in production builds.
    def native_scan_button_tag(label = "Scan", target: nil, event: nil, submit: false, formats: nil, **options)
      if Rails.env.development?
        Rails.logger.warn(
          "[ruby_native] native_scan_button_tag needs a camera usage description set in your " \
          "Ruby Native app settings, or scanning is unavailable in production builds."
        )
      end

      scan_options = {}
      scan_options[:target] = target if target
      scan_options[:event] = event if event
      scan_options[:submit] = true if submit
      if formats
        scan_options[:formats] = Array(formats).flat_map { |f| f.to_s.split(",") }.map(&:strip).reject(&:empty?)
      end

      # A bare <button> is type="submit" inside a form, and the documented usage
      # puts this inside form_with. Without this a tap would submit the form
      # immediately and navigate away before the async scan result arrives, and
      # the `submit:` option (which is what opts into submitting) would be
      # meaningless. Callers who really want a submit button can pass
      # type: "submit" and keep it.
      options[:type] ||= "button"
      options[:onclick] = "window.RubyNative?.scan(#{scan_options.to_json})"
      tag.button(label, **options)
    end

    def native_badge_tag(count = nil, home: nil, tab: nil)
      home = count if count && home.nil?
      tab = count if count && tab.nil?

      data = { native_badge: "" }
      data[:native_badge_home] = home unless home.nil?
      data[:native_badge_tab] = tab unless tab.nil?

      tag.div(data: data, hidden: true)
    end

    def native_navbar_tag(title = nil, pull_to_refresh: true, &block)
      builder = NavbarBuilder.new(self)
      capture(builder, &block) if block

      data = { native_navbar: title.to_s }
      data[:native_pull_to_refresh] = "false" unless pull_to_refresh
      tag.div(data: data, hidden: true) { builder.to_html }
    end

    def native_fab_tag(icon: nil, icons: nil, href: nil, click: nil)
      resolved = RubyNative::Helper.resolve_icon(icon: icon, icons: icons, platform: try(:native_platform))
      raise ArgumentError, "native_fab_tag requires an icon" if resolved.nil?
      data = { native_fab: true, native_icon: resolved }
      data[:native_href] = href if href
      data[:native_click] = click if click
      tag.div(data: data, hidden: true)
    end

    def native_overscroll_tag(top:, bottom: nil)
      tag.div(data: { native_overscroll_top: top, native_overscroll_bottom: bottom || top }, hidden: true)
    end

    def native_haptic_data(feedback = :success, **data)
      feedback = feedback.to_s
      feedback = "success" if feedback.empty?
      data[:native_haptic] = feedback
      data
    end

    # Renders a signal element that asks the app to request an App Store
    # rating from the user. The system decides whether to actually show the
    # prompt (Apple throttles it to a few times per year), so it is safe to
    # render this on any page where a review would be welcome, like a
    # confirmation screen after the user finishes something worthwhile.
    #
    # See Apple's docs on requesting App Store reviews:
    # https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
    def native_review_tag
      tag.div(data: { native_review: true }, hidden: true)
    end

    # Picks the right icon name for the current native platform. Accepts the
    # single `icon:` form (applied to every platform) and/or the `icons:` hash
    # form (`{ ios: "...", android: "..." }`). When both are given, a matching
    # `icons[platform]` wins; otherwise falls back to `icon`. Returns nil when
    # nothing resolves.
    #
    # A non-Hash `icons:` raises rather than falling through. `icons: [ios:
    # "...", android: "..."]` is an easy slip in ERB and yields an Array holding
    # one Hash, which used to skip the lookup and fall back to `icon` — usually
    # nil, so the button rendered with no icon on either platform and nothing
    # said why. That reads as "per-platform icons are broken" rather than "wrong
    # bracket," and it is invisible on whichever platform you aren't testing.
    def self.resolve_icon(icon: nil, icons: nil, platform: nil)
      if !icons.nil? && !icons.is_a?(Hash)
        raise ArgumentError,
          "icons: must be a Hash like { ios: \"square.and.arrow.up\", android: \"share\" }, " \
          "got #{icons.class}. Check for square brackets instead of curly braces."
      end

      if icons.is_a?(Hash) && platform
        key = platform.to_sym
        per_platform = icons[key] || icons[key.to_s]
        return per_platform if per_platform
      end

      # Nothing matched, which is every web render: `native_platform` is nil in
      # a browser. Fall back to `icon:`, then to any name in `icons:`, the same
      # order `RubyNative.backfill_tab_icons` uses for the YAML config.
      #
      # Returning nil here instead would make `icons:` alone unusable, because
      # `native_fab_tag` raises on a nil icon and would 500 a page that renders
      # fine inside the app. The signal element is hidden and only read by the
      # native app, so which name survives on the web doesn't matter.
      icon || fallback_icon(icons)
    end

    def self.fallback_icon(icons)
      return nil unless icons.is_a?(Hash)

      icons[:ios] || icons["ios"] || icons[:android] || icons["android"]
    end
    private_class_method :fallback_icon

    class NavbarBuilder
      def initialize(context)
        @context = context
        @items = []
      end

      def button(title = nil, icon: nil, icons: nil, href: nil, click: nil, position: :trailing, selected: false, &block)
        resolved = RubyNative::Helper.resolve_icon(icon: icon, icons: icons, platform: @context.try(:native_platform))
        data = { native_button: "" }
        data[:native_title] = title if title
        data[:native_icon] = resolved if resolved
        data[:native_href] = href if href
        data[:native_click] = click if click
        data[:native_position] = position.to_s
        data[:native_selected] = "" if selected

        if block
          menu = NavbarMenuBuilder.new(@context)
          @context.capture(menu, &block)
          add(@context.tag.div(data: data) { menu.to_html })
        else
          add(@context.tag.div(data: data))
        end
      end

      # Adds a segment to the nav bar. On iOS the segments render as a centered
      # segmented control (the same control the App Store uses for Apps/Games).
      # Mark the current page's segment `selected: true`. Tapping a segment
      # navigates to its `href` (or clicks the `click` selector), replacing
      # history so the back button doesn't walk back through segment switches.
      def segment(title, href: nil, click: nil, selected: false)
        data = { native_segment: "", native_title: title }
        data[:native_href] = href if href
        data[:native_click] = click if click
        data[:native_selected] = "" if selected
        add(@context.tag.div(data: data))
      end

      # Adds a native share button to the nav bar. Tapping it opens the
      # platform share sheet for `url:` (defaults to the current page on the
      # web side) so it works even where embedded web views don't support
      # `navigator.share`. Icons follow the same rules as the other navbar
      # buttons: `icon:` applies to every platform and `icons:` ({ ios:,
      # android: }) overrides per platform.
      def share_button(url: nil, title: "Share", icon: "square.and.arrow.up", icons: nil, position: :trailing)
        resolved = RubyNative::Helper.resolve_icon(icon: icon, icons: icons, platform: @context.try(:native_platform))
        data = { native_button: "", native_share: "" }
        data[:native_title] = title if title
        data[:native_icon] = resolved if resolved
        data[:native_position] = position.to_s
        data[:native_share_url] = url if url
        add(@context.tag.div(data: data))
      end

      def submit_button(title: "Save", click: "[type='submit']")
        add(@context.tag.div(data: {
          native_submit_button: "",
          native_title: title,
          native_click: click
        }))
      end

      def to_html
        @context.safe_join(@items)
      end

      private

      # Collects a signal element and returns a blank, html-safe string. That
      # lets the builder read naturally with `<%=` in ERB (`<%= navbar.button %>`)
      # without emitting anything, since the nav bar renders from the collected
      # items in `to_html`, not from these return values. Silent `<% %>` tags
      # keep working too.
      def add(item)
        @items << item
        ActiveSupport::SafeBuffer.new
      end
    end

    class NavbarMenuBuilder
      def initialize(context)
        @context = context
        @items = []
      end

      def item(title, href: nil, click: nil, icon: nil, icons: nil, selected: false)
        resolved = RubyNative::Helper.resolve_icon(icon: icon, icons: icons, platform: @context.try(:native_platform))
        data = { native_menu_item: "", native_title: title }
        data[:native_href] = href if href
        data[:native_click] = click if click
        data[:native_icon] = resolved if resolved
        data[:native_selected] = "" if selected
        add(@context.tag.div(data: data))
      end

      # Adds a share entry to a navbar button's dropdown menu. Selecting it
      # opens the platform share sheet for `url:` (defaults to the current
      # page on the web side). Icons follow the same `icon:`/`icons:` rules
      # as the other menu items.
      def share_item(title = "Share", url: nil, icon: "square.and.arrow.up", icons: nil, selected: false)
        resolved = RubyNative::Helper.resolve_icon(icon: icon, icons: icons, platform: @context.try(:native_platform))
        data = { native_menu_item: "", native_title: title, native_share: "" }
        data[:native_share_url] = url if url
        data[:native_icon] = resolved if resolved
        data[:native_selected] = "" if selected
        add(@context.tag.div(data: data))
      end

      def to_html
        @context.safe_join(@items)
      end

      private

      # See NavbarBuilder#add: collects the item and returns a blank, html-safe
      # string so menu items read naturally with `<%= menu.item %>` in ERB.
      def add(item)
        @items << item
        ActiveSupport::SafeBuffer.new
      end
    end
  end
end
