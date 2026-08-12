module RubyNative
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Ruby Native config file at config/ruby_native.yml"

      def copy_config
        template "ruby_native.yml", "config/ruby_native.yml"
      end

      def add_allowed_host
        host_line = %(  config.hosts << ".trycloudflare.com" if config.hosts.is_a?(Array)\n)
        dev_config = "config/environments/development.rb"

        return unless File.exist?(File.join(destination_root, dev_config))
        contents = File.read(File.join(destination_root, dev_config))
        return if contents.include?("trycloudflare")

        # Match any configure block, not just Rails.application.configure; some
        # apps use MyApp::Application.configure and Thor's environment helper
        # silently skips those.
        configure_block = /^[\w:.]+\.configure do\s*\n/
        if contents.match?(configure_block)
          inject_into_file dev_config, host_line, after: configure_block, verbose: false
          say "  Added .trycloudflare.com to allowed hosts in development.rb", :green
        else
          say "  Couldn't find a configure block in development.rb. Add this line inside it:", :yellow
          say "  #{host_line.strip}", :yellow
        end
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
        say "       <%= native_identity_tag(current_user&.id) %>"
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
