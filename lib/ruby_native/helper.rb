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
    def self.resolve_icon(icon: nil, icons: nil, platform: nil)
      if icons.is_a?(Hash) && platform
        key = platform.to_sym
        per_platform = icons[key] || icons[key.to_s]
        return per_platform if per_platform
      end
      icon
    end

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
          @items << @context.tag.div(data: data) { menu.to_html }
        else
          @items << @context.tag.div(data: data)
        end
      end

      def submit_button(title: "Save", click: "[type='submit']")
        @items << @context.tag.div(data: {
          native_submit_button: "",
          native_title: title,
          native_click: click
        })
      end

      def to_html
        @context.safe_join(@items)
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
        @items << @context.tag.div(data: data)
      end

      def to_html
        @context.safe_join(@items)
      end
    end
  end
end
