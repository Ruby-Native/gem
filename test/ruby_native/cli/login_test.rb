require "test_helper"
require "tmpdir"
require "ruby_native/cli/login"

class RubyNative::CLI::LoginTest < Minitest::Test
  # `run` saves the token it collects, so point the credentials file at a temp
  # dir rather than the real ~/.ruby_native. Same swap credentials_test.rb uses.
  def setup
    @tmpdir = Dir.mktmpdir
    @original_path = RubyNative::CLI::Credentials::PATH
    RubyNative::CLI::Credentials.send(:remove_const, :PATH)
    RubyNative::CLI::Credentials.const_set(:PATH, File.join(@tmpdir, "credentials"))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    RubyNative::CLI::Credentials.send(:remove_const, :PATH)
    RubyNative::CLI::Credentials.const_set(:PATH, @original_path)
  end

  # The authorize URL is the part someone else can be talked into opening, so it
  # must carry only the hash. Claiming the token needs the verifier, which stays
  # on this machine.
  def test_the_browser_url_carries_the_hash_and_the_poll_carries_its_preimage
    browser_url, polled = run_login

    challenge = URI.decode_www_form(URI(browser_url).query).to_h.fetch("challenge")

    assert_match(/\A[a-f0-9]{64}\z/, challenge)
    assert_equal Digest::SHA256.hexdigest(polled), challenge
    refute_includes browser_url, polled
  end

  def test_a_fresh_verifier_per_run
    first_browser, first_polled = run_login
    second_browser, second_polled = run_login

    refute_equal first_polled, second_polled
    refute_equal first_browser, second_browser
  end

  def test_the_collected_token_is_saved
    run_login

    assert_equal "a-token", RubyNative::CLI::Credentials.file_token
  end

  private

  def run_login
    login = RubyNative::CLI::Login.new
    browser_url = nil
    polled = nil

    login.define_singleton_method(:open_browser) { |url| browser_url = url }
    login.define_singleton_method(:poll_for_token) { |verifier|
      polled = verifier
      "a-token"
    }

    capture_io { login.run }

    [browser_url, polled]
  end
end
