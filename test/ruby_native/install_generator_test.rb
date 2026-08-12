require "test_helper"
require "rails/generators/test_case"
require "generators/ruby_native/install_generator"

class RubyNative::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests RubyNative::Generators::InstallGenerator
  destination File.expand_path("../../tmp/install_generator", __dir__)
  setup :prepare_destination

  HOST_LINE = %(config.hosts << ".trycloudflare.com" if config.hosts.is_a?(Array))

  def test_adds_guarded_host_line_to_standard_configure_block
    write_dev_config <<~RUBY
      Rails.application.configure do
        config.enable_reloading = true
      end
    RUBY

    run_generator

    assert_dev_config_includes "Rails.application.configure do\n  #{HOST_LINE}\n"
  end

  def test_adds_host_line_to_custom_configure_block
    write_dev_config <<~RUBY
      Backerkit::Application.configure do
        config.enable_reloading = true
      end
    RUBY

    run_generator

    assert_dev_config_includes "Backerkit::Application.configure do\n  #{HOST_LINE}\n"
  end

  def test_leaves_file_alone_when_no_configure_block_exists
    write_dev_config "# frozen_string_literal: true\n"

    output = run_generator

    refute_includes dev_config_contents, "trycloudflare"
    assert_includes output, "Add this line inside it"
  end

  def test_does_not_duplicate_an_existing_host_line
    write_dev_config <<~RUBY
      Rails.application.configure do
        config.hosts << ".trycloudflare.com"
      end
    RUBY

    run_generator

    assert_equal 1, dev_config_contents.scan("trycloudflare").count
  end

  def test_runs_without_a_development_environment_file
    run_generator

    assert_file "config/ruby_native.yml"
  end

  private

  def write_dev_config(contents)
    dir = File.join(destination_root, "config/environments")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "development.rb"), contents)
  end

  def dev_config_contents
    File.read(File.join(destination_root, "config/environments/development.rb"))
  end

  def assert_dev_config_includes(snippet)
    assert_includes dev_config_contents, snippet
  end
end
