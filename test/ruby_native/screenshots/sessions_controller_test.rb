require "test_helper"

class RubyNative::Screenshots::SessionsControllerTest < ActionDispatch::IntegrationTest
  KEY = "test-screenshot-key-9d2bcb05f2c9a31a4e7c84c1f0f99f9e".freeze

  def setup
    @sign_in_calls = 0
    RubyNative.screenshot_key = KEY
    RubyNative.screenshot_sign_in = ->(_helper) { @sign_in_calls += 1 }
  end

  def teardown
    RubyNative.screenshot_key = nil
    RubyNative.screenshot_sign_in = nil
  end

  def test_returns_404_when_config_not_set
    RubyNative.screenshot_key = nil
    RubyNative.screenshot_sign_in = nil

    get "/native/screenshots/session"

    assert_response :not_found
    assert_equal 0, @sign_in_calls
  end

  def test_returns_404_when_key_set_but_sign_in_lambda_missing
    RubyNative.screenshot_sign_in = nil

    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY}

    assert_response :not_found
    assert_equal 0, @sign_in_calls
  end

  def test_returns_401_with_no_key
    get "/native/screenshots/session"

    assert_response :unauthorized
    assert_equal 0, @sign_in_calls
  end

  def test_returns_401_with_wrong_key
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: "wrong"}

    assert_response :unauthorized
    assert_equal 0, @sign_in_calls
  end

  def test_signs_in_with_valid_url_param_key
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY, return_to: "/dashboard"}

    assert_response :redirect
    assert_redirected_to "/dashboard"
    assert_equal 1, @sign_in_calls
  end

  def test_signs_in_with_valid_header_key
    get "/native/screenshots/session", headers: {"X-RubyNative-Screenshot-Key" => KEY}

    assert_response :redirect
    assert_redirected_to "/"
    assert_equal 1, @sign_in_calls
  end

  def test_sets_session_marker_cookie
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY}

    assert_response :redirect
    set_cookie = response.headers["set-cookie"].to_s
    assert set_cookie.include?("_ruby_native_screenshot_session"), "Expected session marker cookie"
    assert set_cookie.downcase.include?("httponly"), "Expected HttpOnly flag"
  end

  def test_sets_referrer_policy_no_referrer
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY}

    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end

  def test_rejects_protocol_relative_return_to
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY, return_to: "//evil.com/x"}

    assert_response :redirect
    assert_redirected_to "/"
  end

  def test_rejects_external_return_to
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY, return_to: "https://evil.com/x"}

    assert_response :redirect
    assert_redirected_to "/"
  end

  def test_defaults_return_to_when_blank
    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY}

    assert_response :redirect
    assert_redirected_to "/"
  end

  # Regression: in Rails 8.1 `cookies` is private on `ActionController::Base`,
  # so the lambda used to fail with `NoMethodError` when it tried to set a
  # signed cookie. The helper exposes `cookies` publicly so customer code
  # like `helper.cookies.signed.permanent[:foo] = ...` works without
  # `controller.send(:cookies)`.
  def test_helper_exposes_writable_cookies
    RubyNative.screenshot_sign_in = ->(helper) {
      helper.cookies.signed.permanent[:fake_user_session_id] = {
        value: "42",
        httponly: true,
        same_site: :lax
      }
    }

    get "/native/screenshots/session", params: {ruby_native_screenshot_key: KEY}

    assert_response :redirect
    set_cookie = response.headers["set-cookie"].to_s
    assert set_cookie.include?("fake_user_session_id"), "Expected helper.cookies.signed write to set fake_user_session_id"
  end
end
