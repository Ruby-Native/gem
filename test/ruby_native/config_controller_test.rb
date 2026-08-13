require "test_helper"

class RubyNative::ConfigControllerTest < ActionDispatch::IntegrationTest
  def teardown
    RubyNative.load_config
  end

  def test_serves_the_config_with_the_version_header
    RubyNative.load_config

    get "/native/config.json"

    assert_response :ok
    assert_equal RubyNative::VERSION, response.headers["X-Ruby-Native-Version"]
    assert_equal "Test App", JSON.parse(response.body).dig("app", "name")
  end

  # The version header stays on the 404 so `ruby_native preview` can tell
  # missing config apart from an unmounted engine.
  def test_missing_config_file_returns_a_classifiable_404
    without_config_file do
      RubyNative.config = nil

      get "/native/config.json"

      assert_response :not_found
      assert_equal RubyNative::VERSION, response.headers["X-Ruby-Native-Version"]
      assert_match(/missing or empty/, JSON.parse(response.body)["error"])
    end
  end

  private

  def without_config_file
    path = Rails.root.join("config", "ruby_native.yml")
    original = path.read
    path.delete
    yield
  ensure
    File.write(path, original)
  end
end
