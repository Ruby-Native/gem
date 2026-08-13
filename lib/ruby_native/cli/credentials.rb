require "json"
require "fileutils"

module RubyNative
  class CLI
    class Credentials
      class << self
        attr_writer :path
      end

      # Lazy: Dir.home raises in HOME-less containers, and that must not kill
      # commands that only use RUBY_NATIVE_TOKEN.
      def self.path
        @path ||= File.join(Dir.home, ".ruby_native", "credentials")
      end

      def self.token
        env_token || file_token
      end

      # A misspelled CI secret interpolates to "", which must not shadow the
      # credentials file or `ruby_native login` can never fix auth.
      def self.env_token
        value = ENV["RUBY_NATIVE_TOKEN"].to_s.strip
        value unless value.empty?
      end

      def self.file_token
        return unless File.exist?(path)
        JSON.parse(File.read(path))["token"]
      rescue JSON::ParserError, ArgumentError
        nil
      end

      def self.save(token)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.generate(token: token))
        File.chmod(0600, path)
      end

      def self.clear
        File.delete(path) if File.exist?(path)
      end
    end
  end
end
