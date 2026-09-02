require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "ruby_native/cli/check"

class CheckTest < Minitest::Test
  def test_a_clean_app_passes
    output = check(<<~ERB)
      <div data-native-tabs hidden></div>
      <%= link_to "Home", "/" %>
    ERB

    assert_match "Checked 1 template. No problems found.", output
  end

  def test_a_typo_is_an_error_with_a_suggestion
    output = check("<div data-native-tab hidden></div>", status: 1)

    assert_match "error", output
    assert_match "Unknown signal `data-native-tab`. Did you mean `data-native-tabs`?", output
  end

  def test_an_unrelated_attribute_is_reported_without_a_guess
    output = check("<div data-native-wombat hidden></div>", status: 1)

    assert_match "Unknown signal `data-native-wombat`.", output
    refute_match "Did you mean", output
  end

  def test_a_duplicate_singleton_is_a_warning_and_does_not_fail
    output = check(<<~ERB)
      <div data-native-tabs hidden></div>
      <div data-native-tabs hidden></div>
    ERB

    assert_match "2 elements carry `data-native-tabs`; only the first one is used.", output
    assert_match "0 errors, 1 warning", output
  end

  def test_a_repeated_non_singleton_is_fine
    output = check(<<~ERB)
      <button data-native-menu-item="a">A</button>
      <button data-native-menu-item="b">B</button>
    ERB

    assert_match "No problems found.", output
  end

  def test_erb_in_attribute_position_fails_to_compile
    output = check(%(<option value="a" <%= "selected" if @x %>>A</option>), status: 1)

    assert_match "not allowed in attribute position", output
  end

  def test_a_template_that_does_not_compile_reports_only_the_compile_error
    output = check(%(<div data-native-tab <%= "hidden" if @x %>></div>), status: 1)

    assert_match "attribute position", output
    refute_match "Unknown signal", output
  end

  def test_a_signal_newer_than_the_gem_is_an_error
    with_version("0.14.0") do
      output = check("<div data-native-keyboard-toolbar hidden></div>", status: 1)

      assert_match "`data-native-keyboard-toolbar` needs Ruby Native 0.15.0, but this app is on 0.14.0.", output
    end
  end

  def test_a_signal_the_gem_already_has_passes
    with_version("0.15.0") do
      assert_match "No problems found.", check("<div data-native-keyboard-toolbar hidden></div>")
    end
  end

  def test_a_signal_whose_value_comes_from_erb_is_still_recognized
    assert_match "No problems found.", check(%(<div data-native-badge-tab="<%= @count %>" hidden></div>))
  end

  # Herb rejects these outright, so the scan never sees the attribute. Worth
  # pinning: it is why the collector does not need to resolve dynamic names.
  def test_an_attribute_name_built_from_erb_fails_to_compile
    output = check(%(<div <%= @attribute %>="x"></div>), status: 1)

    assert_match "ERB output in attribute names is not allowed", output
  end

  def test_signals_outside_the_scanned_paths_are_not_checked
    output = check("<div data-native-tab hidden></div>", paths: "app/components")

    assert_match "No .html.erb templates found in app/components.", output
  end

  def test_an_app_with_no_templates_says_so
    in_app do
      assert_match "No .html.erb templates found", run_check([])
    end
  end

  def test_a_signal_newer_than_the_deployed_build_is_an_error
    offenses = deployed_offenses_for("ios", built: "0.9.2", signal: "data-native-keyboard-toolbar")

    assert_equal 1, offenses.size
    assert_equal "`data-native-keyboard-toolbar` needs 0.15.0, but the ios build users have was made on 0.9.2.",
      offenses.first.message
  end

  def test_a_signal_the_deployed_build_already_understands_passes
    assert_empty deployed_offenses_for("ios", built: "0.15.3", signal: "data-native-keyboard-toolbar")
  end

  def test_a_shell_written_signal_is_never_compared_against_a_build
    assert_empty deployed_offenses_for("ios", built: "0.1.2", signal: "data-native-app")
  end

  def test_an_unreachable_api_reports_nothing_rather_than_failing
    check = RubyNative::CLI::Check.new(["--deployed"])
    check.define_singleton_method(:latest_build_version) { |*| nil }

    assert_empty check.send(:deployed_offenses_for, "ios", "app_1", { "data-native-tabs" => ["a.erb", 1] })
  end

  private

  def deployed_offenses_for(platform, built:, signal:)
    check = RubyNative::CLI::Check.new(["--deployed"])
    check.define_singleton_method(:latest_build_version) { |*| built }

    check.send(:deployed_offenses_for, platform, "app_1", { signal => ["app/views/pages/show.html.erb", 3] })
  end

  def check(template, status: 0, paths: nil)
    in_app do
      FileUtils.mkdir_p("app/views/pages")
      File.write("app/views/pages/show.html.erb", template)

      run_check(paths ? ["--paths=#{paths}"] : [], status: status)
    end
  end

  def run_check(argv, status: 0)
    output, exited = capture_exit { RubyNative::CLI::Check.new(argv).run }

    assert_equal status, exited, "expected exit #{status}\n#{output}"
    output
  end

  def in_app(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &block)
    end
  end

  # `run` exits on failure, so the status is part of what each case asserts.
  def capture_exit
    exited = 0

    output, = capture_io do
      yield
    rescue SystemExit => error
      exited = error.status
    end

    [output, exited]
  end

  def with_version(version)
    original = RubyNative::VERSION
    RubyNative.send(:remove_const, :VERSION)
    RubyNative.const_set(:VERSION, version)
    yield
  ensure
    RubyNative.send(:remove_const, :VERSION)
    RubyNative.const_set(:VERSION, original)
  end
end
