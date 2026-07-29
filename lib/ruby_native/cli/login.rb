require "digest"
require "securerandom"
require "net/http"
require "uri"
require "json"
require "ruby_native/cli/credentials"

module RubyNative
  class CLI
    class Login
      HOST = ENV.fetch("RUBY_NATIVE_HOST", "https://rubynative.com")

      def initialize(argv = [])
      end

      def run
        # Only the hash goes through the browser. Claiming the token needs this
        # verifier, which never leaves the machine, so a copy of the authorize
        # URL is not enough for anyone else to collect the session.
        verifier = SecureRandom.hex(32)
        challenge = Digest::SHA256.hexdigest(verifier)
        url = "#{HOST}/cli/session/new?challenge=#{challenge}"

        puts "Opening browser to authorize..."
        open_browser(url)
        puts "Waiting for authorization..."

        token = poll_for_token(verifier)

        if token
          Credentials.save(token)
          puts "Logged in to Ruby Native."
        else
          puts "Authorization timed out. Please try again."
          exit 1
        end
      end

      private

      def open_browser(url)
        case RUBY_PLATFORM
        when /darwin/
          system("open", url)
        when /linux/
          system("xdg-open", url)
        when /mingw|mswin/
          system("start", url)
        end
      end

      def poll_for_token(verifier)
        uri = URI("#{HOST}/cli/session/poll?verifier=#{verifier}")
        attempts = 0
        max_attempts = 60

        loop do
          attempts += 1
          return nil if attempts > max_attempts

          sleep 2

          response = Net::HTTP.get_response(uri)
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            return data["token"]
          end
        end
      rescue Interrupt
        nil
      end
    end
  end
end
