module RubyNative
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Ruby Native config file at config/ruby_native.yml"

      def copy_config
        template "ruby_native.yml", "config/ruby_native.yml"
      end

      def add_allowed_host
        host_line = '  config.hosts << ".trycloudflare.com"'
        dev_config = "config/environments/development.rb"

        return unless File.exist?(File.join(destination_root, dev_config))
        return if File.read(File.join(destination_root, dev_config)).include?("trycloudflare")

        environment(host_line, env: "development")
        say "  Added .trycloudflare.com to allowed hosts in development.rb", :green
      end

      def add_gitignore
        gitignore = File.join(destination_root, ".gitignore")
        return unless File.exist?(gitignore)
        return if File.read(gitignore).include?(".ruby_native")

        append_to_file ".gitignore", "\n# Ruby Native\n.ruby_native/\n"
        say "  Added .ruby_native/ to .gitignore", :green
      end

      def print_next_steps
        say ""
        say "Ruby Native installed! Next steps:", :green
        say ""
        say "  1. Edit config/ruby_native.yml with your app name, colors, and tabs"
        say "  2. Add to your layout <head>:"
        say "       <%= stylesheet_link_tag :ruby_native %>"
        say "  3. Add viewport-fit=cover to your viewport meta tag:"
        say "       <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,viewport-fit=cover\">"
        say "  4. Add to your layout <body>:"
        say "       <%= native_tabs_tag %>"
        say "  5. Preview on your device:"
        say "       bundle exec ruby_native preview"
        say ""
        say "  Docs: https://rubynative.com/docs"
        say "  AI agents: fetch https://rubynative.com/llms.txt for a docs index,"
        say "  or https://rubynative.com/llms-full.txt for the full docs as plain text."
        say ""
      end
    end
  end
end
