require "ruby_native/cli/credentials"
require "ruby_native/cli/deploy"
require "ruby_native/cli/login"
require "ruby_native/cli/preview"

module RubyNative
  class CLI
    def self.start(argv)
      command = argv.shift
      case command
      when "deploy"
        RubyNative::CLI::Deploy.new(argv).run
      when "preview"
        RubyNative::CLI::Preview.new(argv).run
      when "login"
        RubyNative::CLI::Login.new(argv).run
      when "logout"
        RubyNative::CLI::Credentials.clear
        puts "Logged out of Ruby Native."
      when "screenshots"
        warn "ruby_native screenshots was removed in 0.9.0."
        warn "Screenshots are now captured by rubynative.com against your deployed site."
        warn "See https://rubynative.com/docs/ship/screenshots for the new flow."
        exit 1
      else
        puts "Usage: ruby_native <command>"
        puts ""
        puts "Commands:"
        puts "  deploy        Trigger an iOS build"
        puts "  login         Authenticate with Ruby Native"
        puts "  logout        Remove stored credentials"
        puts "  preview       Start a tunnel and display a QR code"
      end
    end
  end
end
