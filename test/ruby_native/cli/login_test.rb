require "test_helper"
require "tmpdir"
require "ruby_native/cli/login"

class RubyNative::CLI::LoginTest < Minitest::Test
  # `run` saves the token it collects, so point the credentials file at a temp
  # dir rather than the real ~/.ruby_native. Same swap credentials_test.rb uses.
  def setup
    @tmpdir = Dir.mktmpdir
    @original_path = RubyNative::CLI::Credentials.path
    RubyNative::CLI::Credentials.path = File.join(@tmpdir, "credentials")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    RubyNative::CLI::Credentials.path = @original_path
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

  # Headless and SSH sessions have no browser to open, so the URL itself is the
  # only workaround.
  def test_the_authorize_url_is_always_printed
    browser_url, _polled, output = run_login

    assert_includes output, browser_url
  end

  def test_a_pending_flow_times_out_with_the_generic_message
    output = run_failing_login(Net::HTTPNotFound.new("1.1", "404", "Not Found"))

    assert_match(/Authorization timed out/, output)
  end

  def test_repeated_server_errors_are_reported_instead_of_blaming_the_user
    output = run_failing_login(Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error"))

    assert_match(/HTTP 500/, output)
    refute_match(/Authorization timed out/, output)
  end

  def test_a_success_with_a_non_json_body_is_reported
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, "<html>WAF</html>")
    response.instance_variable_set(:@read, true)

    output = run_failing_login(response)

    assert_match(/not JSON/, output)
  end

  def test_network_errors_while_polling_do_not_crash
    login = RubyNative::CLI::Login.new
    login.define_singleton_method(:open_browser) { |_url| }
    login.define_singleton_method(:sleep) { |_| }

    raising_http = Object.new
    def raising_http.use_ssl=(_value); end
    def raising_http.open_timeout=(_value); end
    def raising_http.read_timeout=(_value); end
    def raising_http.request(_req) = raise SocketError, "getaddrinfo: nodename nor servname provided"

    output = nil
    with_net_http(raising_http) do
      output, _err = capture_io do
        assert_raises(SystemExit) { login.run }
      end
    end

    assert_match(/Could not reach/, output)
    assert_match(/SocketError/, output)
  end

  def test_the_poll_sets_timeouts
    login = RubyNative::CLI::Login.new
    http = Struct.new(:use_ssl, :open_timeout, :read_timeout) do
      def request(_req)
        Net::HTTPNotFound.new("1.1", "404", "Not Found")
      end
    end.new

    with_net_http(http) do
      login.send(:poll_once, URI("https://rubynative.com/cli/session/poll?verifier=x"))
    end

    assert_equal 5, http.open_timeout
    assert_equal 5, http.read_timeout
  end

  private

  # Minitest 6 dropped minitest/mock, so swap the singleton method by hand.
  # Remove-then-define keeps the redefinition warnings out of the test output.
  def with_net_http(fake)
    original = Net::HTTP.method(:new)
    Net::HTTP.singleton_class.send(:remove_method, :new)
    Net::HTTP.define_singleton_method(:new) { |*_args| fake }
    yield
  ensure
    Net::HTTP.singleton_class.send(:remove_method, :new)
    Net::HTTP.define_singleton_method(:new, original)
  end

  def run_login
    login = RubyNative::CLI::Login.new
    browser_url = nil
    polled = nil

    login.define_singleton_method(:open_browser) { |url| browser_url = url }
    login.define_singleton_method(:poll_for_token) { |verifier|
      polled = verifier
      "a-token"
    }

    output, _err = capture_io { login.run }

    [browser_url, polled, output]
  end

  def run_failing_login(response)
    login = RubyNative::CLI::Login.new
    login.define_singleton_method(:open_browser) { |_url| }
    login.define_singleton_method(:sleep) { |_| }
    login.define_singleton_method(:poll_once) { |_uri| response }

    output, _err = capture_io do
      assert_raises(SystemExit) { login.run }
    end
    output
  end
end
