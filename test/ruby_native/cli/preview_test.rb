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

  private

  def stub_http_response(response)
    @preview.define_singleton_method(:fetch_config_response) { |_uri| response }
  end

  def stub_http_raise(error)
    @preview.define_singleton_method(:fetch_config_response) { |_uri| raise error }
  end
end
