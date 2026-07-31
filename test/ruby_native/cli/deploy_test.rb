require "minitest/autorun"
require "ruby_native/cli/deploy"

class DeployTest < Minitest::Test
  def test_skip_build_when_gem_version_matches
    deploy = build_deploy(gem_version: RubyNative::VERSION)
    assert deploy.send(:skip_build?, "app_123")
  end

  def test_no_skip_when_gem_version_is_older
    deploy = build_deploy(gem_version: "0.1.0")
    refute deploy.send(:skip_build?, "app_123")
  end

  def test_no_skip_when_no_prior_build
    deploy = build_deploy(latest_build: nil)
    refute deploy.send(:skip_build?, "app_123")
  end

  def test_no_skip_when_gem_version_is_nil
    deploy = build_deploy(gem_version: nil)
    refute deploy.send(:skip_build?, "app_123")
  end

  def test_skip_when_latest_version_is_ahead
    deploy = build_deploy(gem_version: "99.0.0")
    assert deploy.send(:skip_build?, "app_123")
  end

  def test_no_skip_on_malformed_version
    deploy = build_deploy(gem_version: "not.a.version")
    refute deploy.send(:skip_build?, "app_123")
  end

  def test_latest_build_request_is_platform_scoped
    deploy = RubyNative::CLI::Deploy.new(["--android"])
    captured = nil
    deploy.define_singleton_method(:make_request) do |uri, _req|
      captured = uri
      Net::HTTPNoContent.new("1.1", "204", "No Content")
    end
    deploy.send(:fetch_latest_build, "app_123")
    assert_includes captured.to_s, "platform=android"
  end

  private

  def build_deploy(latest_build: {}, gem_version: nil)
    latest_build = latest_build&.merge("gem_version" => gem_version)
    deploy = RubyNative::CLI::Deploy.new([])
    deploy.define_singleton_method(:fetch_latest_build) { |_app_id| latest_build }
    deploy
  end
end
