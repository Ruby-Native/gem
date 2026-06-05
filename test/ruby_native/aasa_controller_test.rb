require "test_helper"

class RubyNative::AasaControllerTest < ActionDispatch::IntegrationTest
  PATH = "/.well-known/apple-app-site-association"

  def setup
    @original_config = RubyNative.config
    RubyNative.config = (RubyNative.config || {}).deep_merge(
      ios: { bundle_id: "com.example.test", team_id: "ABCD123456" }
    )
  end

  def teardown
    RubyNative.config = @original_config
  end

  def test_returns_AASA_json_for_configured_ios_app
    get PATH

    assert_response :ok
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal "no-cache", response.headers["Cache-Control"]

    body = JSON.parse(response.body)
    assert_equal({
      "applinks" => {
        "details" => [
          {
            "appIDs" => [ "ABCD123456.com.example.test" ],
            "components" => [
              { "/" => "/auth/test_provider*", "exclude" => true },
              { "/" => "*" }
            ]
          }
        ]
      },
      "webcredentials" => {
        "apps" => [ "ABCD123456.com.example.test" ]
      }
    }, body)
  end

  def test_excludes_each_configured_oauth_path_before_the_catch_all
    RubyNative.config = RubyNative.config.deep_merge(
      auth: { oauth_paths: [ "/users/auth/google_oauth2", "/users/auth/github" ] }
    )

    get PATH

    components = JSON.parse(response.body).dig("applinks", "details", 0, "components")
    assert_equal [
      { "/" => "/users/auth/google_oauth2*", "exclude" => true },
      { "/" => "/users/auth/github*", "exclude" => true },
      { "/" => "*" }
    ], components
  end

  def test_serves_only_the_catch_all_without_oauth_paths
    RubyNative.config = RubyNative.config.deep_merge(auth: { oauth_paths: nil })

    get PATH

    components = JSON.parse(response.body).dig("applinks", "details", 0, "components")
    assert_equal [ { "/" => "*" } ], components
  end

  def test_returns_404_when_ios_section_is_missing
    RubyNative.config = (@original_config || {}).except(:ios)

    get PATH

    assert_response :not_found
  end

  def test_returns_404_when_bundle_id_is_missing
    RubyNative.config = RubyNative.config.deep_merge(ios: { bundle_id: nil })

    get PATH

    assert_response :not_found
  end

  def test_returns_404_when_team_id_is_missing
    RubyNative.config = RubyNative.config.deep_merge(ios: { team_id: nil })

    get PATH

    assert_response :not_found
  end
end
