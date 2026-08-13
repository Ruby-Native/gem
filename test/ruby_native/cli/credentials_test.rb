require "minitest/autorun"
require "tmpdir"
require "ruby_native/cli/credentials"

class CredentialsTest < Minitest::Test
  def setup
    @original_env = ENV["RUBY_NATIVE_TOKEN"]
    @tmpdir = Dir.mktmpdir
    @original_path = RubyNative::CLI::Credentials.path
    RubyNative::CLI::Credentials.path = File.join(@tmpdir, "credentials")
  end

  def teardown
    ENV["RUBY_NATIVE_TOKEN"] = @original_env
    FileUtils.rm_rf(@tmpdir)
    RubyNative::CLI::Credentials.path = @original_path
  end

  def test_token_returns_env_var_when_set
    ENV["RUBY_NATIVE_TOKEN"] = "env_token_123"

    assert_equal "env_token_123", RubyNative::CLI::Credentials.token
  end

  def test_token_falls_back_to_file
    ENV.delete("RUBY_NATIVE_TOKEN")
    RubyNative::CLI::Credentials.save("file_token_456")

    assert_equal "file_token_456", RubyNative::CLI::Credentials.token
  end

  def test_env_var_takes_priority_over_file
    ENV["RUBY_NATIVE_TOKEN"] = "env_token_123"
    RubyNative::CLI::Credentials.save("file_token_456")

    assert_equal "env_token_123", RubyNative::CLI::Credentials.token
  end

  def test_token_returns_nil_when_no_env_or_file
    ENV.delete("RUBY_NATIVE_TOKEN")

    assert_nil RubyNative::CLI::Credentials.token
  end

  # A misspelled CI secret interpolates to "", which must not shadow the file
  # token or login can never fix auth.
  def test_blank_env_var_falls_back_to_file
    ENV["RUBY_NATIVE_TOKEN"] = ""
    RubyNative::CLI::Credentials.save("file_token_456")

    assert_equal "file_token_456", RubyNative::CLI::Credentials.token
  end

  def test_whitespace_env_var_counts_as_absent
    ENV["RUBY_NATIVE_TOKEN"] = "   "

    assert_nil RubyNative::CLI::Credentials.token
  end

  def test_env_token_is_nil_when_blank
    ENV["RUBY_NATIVE_TOKEN"] = ""

    assert_nil RubyNative::CLI::Credentials.env_token
  end

  # HOME-less containers: Dir.home raises, which must not take down commands
  # that authenticate through the environment.
  def test_file_token_is_nil_when_home_cannot_be_resolved
    ENV.delete("RUBY_NATIVE_TOKEN")
    original = RubyNative::CLI::Credentials.method(:path)
    RubyNative::CLI::Credentials.singleton_class.send(:remove_method, :path)
    RubyNative::CLI::Credentials.define_singleton_method(:path) do
      raise ArgumentError, "couldn't find HOME environment -- expanding `~'"
    end

    assert_nil RubyNative::CLI::Credentials.token
  ensure
    RubyNative::CLI::Credentials.singleton_class.send(:remove_method, :path)
    RubyNative::CLI::Credentials.define_singleton_method(:path, original)
  end
end
