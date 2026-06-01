require "test_helper"

class RubyNative::ConfigTest < Minitest::Test
  def test_load_config_reads_yaml
    RubyNative.load_config
    refute_nil RubyNative.config
  end

  def test_config_is_deep_symbolized
    RubyNative.load_config
    assert_equal "Test App", RubyNative.config[:app][:name]
  end

  def test_config_has_tabs
    RubyNative.load_config
    tabs = RubyNative.config[:tabs]
    assert_equal 1, tabs.length
    assert_equal "Home", tabs.first[:title]
    assert_equal "/", tabs.first[:path]
  end

  def test_config_has_appearance
    RubyNative.load_config
    appearance = RubyNative.config[:appearance]
    assert_equal "#007AFF", appearance[:tint_color]
  end

  def test_entry_path_defaults_to_first_tab_path
    with_config(app: {}, tabs: [{title: "Inbox", path: "/inbox", icon: "tray"}]) do
      RubyNative.load_config
      assert_equal "/inbox", RubyNative.config[:app][:entry_path]
    end
  end

  def test_entry_path_defaults_to_slash_when_no_tabs
    with_config(app: {}, tabs: []) do
      RubyNative.load_config
      assert_equal "/", RubyNative.config[:app][:entry_path]
    end
  end

  def test_entry_path_not_overwritten_when_present
    with_config(app: {entry_path: "/dashboard"}, tabs: [{title: "Home", path: "/", icon: "house"}]) do
      RubyNative.load_config
      assert_equal "/dashboard", RubyNative.config[:app][:entry_path]
    end
  end

  def test_tab_icon_kept_when_explicitly_set
    with_config(app: {}, tabs: [{title: "Home", path: "/", icon: "house", icons: {ios: "house.fill", android: "home"}}]) do
      RubyNative.load_config
      assert_equal "house", RubyNative.config[:tabs].first[:icon]
    end
  end

  def test_tab_icon_backfilled_from_icons_ios
    with_config(app: {}, tabs: [{title: "Profile", path: "/profile", icons: {ios: "person.circle", android: "account_circle"}}]) do
      RubyNative.load_config
      assert_equal "person.circle", RubyNative.config[:tabs].first[:icon]
    end
  end

  def test_tab_icon_backfilled_from_icons_android_when_no_ios
    with_config(app: {}, tabs: [{title: "Profile", path: "/profile", icons: {android: "account_circle"}}]) do
      RubyNative.load_config
      assert_equal "account_circle", RubyNative.config[:tabs].first[:icon]
    end
  end

  private

  def with_config(config)
    path = Rails.root.join("config", "ruby_native.yml")
    original = path.read
    path.write(config.deep_stringify_keys.to_yaml)
    yield
  ensure
    path.write(original)
  end
end
