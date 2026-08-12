require "test_helper"

class RubyNative::AssetlinksControllerTest < ActionDispatch::IntegrationTest
  PATH = "/.well-known/assetlinks.json"

  def setup
    @original_config = RubyNative.config
    RubyNative.load_config
    RubyNative.config = RubyNative.config.deep_merge(
      android: {
        package: "com.example.test",
        cert_fingerprint: "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
      }
    )
  end

  def teardown
    RubyNative.config = @original_config
  end

  def test_returns_assetlinks_json_for_configured_android_app
    get PATH

    assert_response :ok
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal "no-cache", response.headers["Cache-Control"]

    body = JSON.parse(response.body)
    assert_equal [
      {
        "relation" => [
          "delegate_permission/common.handle_all_urls",
          "delegate_permission/common.get_login_creds"
        ],
        "target" => {
          "namespace" => "android_app",
          "package_name" => "com.example.test",
          "sha256_cert_fingerprints" => [
            "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
          ]
        }
      }
    ], body
  end

  def test_accepts_a_list_of_fingerprints
    RubyNative.config = RubyNative.config.deep_merge(
      android: { cert_fingerprint: [ "AA:BB", "CC:DD" ] }
    )

    get PATH

    fingerprints = JSON.parse(response.body).dig(0, "target", "sha256_cert_fingerprints")
    assert_equal [ "AA:BB", "CC:DD" ], fingerprints
  end

  def test_normalizes_fingerprints_to_uppercase
    RubyNative.config = RubyNative.config.deep_merge(
      android: { cert_fingerprint: " aa:bb:cc " }
    )

    get PATH

    fingerprints = JSON.parse(response.body).dig(0, "target", "sha256_cert_fingerprints")
    assert_equal [ "AA:BB:CC" ], fingerprints
  end

  def test_returns_404_when_android_section_is_missing
    RubyNative.config = (@original_config || {}).except(:android)

    get PATH

    assert_response :not_found
  end

  def test_returns_404_when_package_is_missing
    RubyNative.config = RubyNative.config.deep_merge(android: { package: nil })

    get PATH

    assert_response :not_found
  end

  def test_returns_404_when_cert_fingerprint_is_missing
    RubyNative.config = RubyNative.config.deep_merge(android: { cert_fingerprint: nil })

    get PATH

    assert_response :not_found
  end
end
