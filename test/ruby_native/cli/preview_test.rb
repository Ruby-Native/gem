require "minitest/autorun"
require "ruby_native/cli/preview"

class PreviewTest < Minitest::Test
  def setup
    @preview = RubyNative::CLI::Preview.new(["--port", "3000"])
  end

  def test_passes_when_config_endpoint_returns_200
    stub_http_response(Net::HTTPSuccess.new("1.1", "200", "OK"))
    @preview.send(:check_local_server!)
  end

  def test_exits_when_config_endpoint_returns_404
    stub_http_response(Net::HTTPNotFound.new("1.1", "404", "Not Found"))
    out, _err = capture_io do
      assert_raises(SystemExit) { @preview.send(:check_local_server!) }
    end
    assert_match(/returned 404/, out)
    assert_match(/installed and mounted/, out)
  end

  def test_exits_when_server_not_running
    stub_http_raise(Errno::ECONNREFUSED)
    out, _err = capture_io do
      assert_raises(SystemExit) { @preview.send(:check_local_server!) }
    end
    assert_match(/Nothing is running on port 3000/, out)
  end

  def test_exits_on_unexpected_error
    stub_http_raise(SocketError.new("getaddrinfo failed"))
    out, _err = capture_io do
      assert_raises(SystemExit) { @preview.send(:check_local_server!) }
    end
    assert_match(/Could not reach/, out)
  end

  def test_wait_for_tunnel_returns_when_ready
    stub_dns("1.2.3.4")
    @preview.define_singleton_method(:fetch_config_response) { |_uri, ip: nil| Net::HTTPSuccess.new("1.1", "200", "OK") }
    @preview.define_singleton_method(:sleep) { |_| }
    out, _err = capture_io do
      @preview.send(:wait_for_tunnel, "https://example.trycloudflare.com")
    end
    assert_match(/Waiting for tunnel\.\.\. ready\./, out)
  end

  def test_wait_for_tunnel_polls_until_success
    stub_dns("1.2.3.4")
    responses = [
      Net::HTTPNotFound.new("1.1", "404", "Not Found"),
      Net::HTTPNotFound.new("1.1", "404", "Not Found"),
      Net::HTTPSuccess.new("1.1", "200", "OK")
    ]
    @preview.define_singleton_method(:fetch_config_response) { |_uri, ip: nil| responses.shift }
    @preview.define_singleton_method(:sleep) { |_| }
    out, _err = capture_io do
      @preview.send(:wait_for_tunnel, "https://example.trycloudflare.com")
    end
    assert_match(/Waiting for tunnel\.\.\.\.\. ready\./, out)
    assert_empty responses
  end

  def test_wait_for_tunnel_keeps_polling_after_dns_failure
    lookups = [Resolv::ResolvError.new("no A record"), "1.2.3.4"]
    @preview.define_singleton_method(:resolve_via_public_dns) do |_host|
      result = lookups.shift
      raise result if result.is_a?(Exception)
      result
    end
    @preview.define_singleton_method(:fetch_config_response) { |_uri, ip: nil| Net::HTTPSuccess.new("1.1", "200", "OK") }
    @preview.define_singleton_method(:sleep) { |_| }
    out, _err = capture_io do
      @preview.send(:wait_for_tunnel, "https://example.trycloudflare.com")
    end
    assert_match(/Waiting for tunnel\.\.\.\. ready\./, out)
    assert_empty lookups
  end

  def test_wait_for_tunnel_gives_up_after_timeout
    stub_dns("1.2.3.4")
    @preview.define_singleton_method(:fetch_config_response) { |_uri, ip: nil| Net::HTTPNotFound.new("1.1", "404", "Not Found") }
    @preview.define_singleton_method(:sleep) { |_| }
    times = [0, 5, 70]
    @preview.define_singleton_method(:monotonic_now) { times.shift || 999 }
    out, _err = capture_io do
      @preview.send(:wait_for_tunnel, "https://example.trycloudflare.com")
    end
    assert_match(/did not respond within 60s/, out)
  end

  private

  def stub_http_response(response)
    @preview.define_singleton_method(:fetch_config_response) { |_uri| response }
  end

  def stub_http_raise(error)
    @preview.define_singleton_method(:fetch_config_response) { |_uri| raise error }
  end

  def stub_dns(ip)
    @preview.define_singleton_method(:resolve_via_public_dns) { |_host| ip }
  end
end
