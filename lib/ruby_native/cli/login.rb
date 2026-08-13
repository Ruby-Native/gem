require "digest"
require "securerandom"
require "net/http"
require "uri"
require "json"
require "openssl"
require "ruby_native/cli/credentials"

module RubyNative
  class CLI
    class Login
      HOST = ENV.fetch("RUBY_NATIVE_HOST", "https://rubynative.com")
      POLL_INTERVAL = 2
      MAX_ATTEMPTS = 60

      NETWORK_ERRORS = [
        SocketError,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Net::OpenTimeout,
        Net::ReadTimeout,
        OpenSSL::SSL::SSLError
      ].freeze

      def initialize(argv = [])
      end

      def run
        # Only the hash goes through the browser. Claiming the token needs this
        # verifier, which never leaves the machine, so a copy of the authorize
        # URL is not enough for anyone else to collect the session.
        verifier = SecureRandom.hex(32)
        challenge = Digest::SHA256.hexdigest(verifier)
        url = "#{HOST}/cli/session/new?challenge=#{challenge}"

        puts "Opening your browser to authorize. If nothing opens, visit:"
        puts "  #{url}"
        open_browser(url)
        puts "Waiting for authorization..."

        token = poll_for_token(verifier)

        if token
          Credentials.save(token)
          puts "Logged in to Ruby Native."
        else
          print_poll_failure
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

        loop do
          attempts += 1
          return nil if attempts > MAX_ATTEMPTS

          sleep POLL_INTERVAL

          response = poll_once(uri)
          next unless response

          @network_error = nil

          case response
          when Net::HTTPSuccess
            token = parse_token(response)
            return token if token
            @unexpected = "HTTP #{response.code} with a body that is not JSON"
          when Net::HTTPNotFound
            # Pending: the server answers 404 until the browser flow completes.
            @unexpected = nil
          else
            @unexpected = "HTTP #{response.code}"
          end
        end
      rescue Interrupt
        nil
      end

      def poll_once(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 5
        http.read_timeout = 5
        http.request(Net::HTTP::Get.new(uri))
      rescue *NETWORK_ERRORS => error
        @network_error = "#{error.class}: #{error.message}"
        nil
      end

      def parse_token(response)
        JSON.parse(response.body)["token"]
      rescue JSON::ParserError
        nil
      end

      def print_poll_failure
        if @unexpected
          puts "Authorization did not complete. While waiting, #{HOST} kept responding"
          puts "with #{@unexpected}."
          puts "Check that #{HOST} loads in a browser, then run `ruby_native login` again."
        elsif @network_error
          puts "Could not reach #{HOST} (#{@network_error})."
          puts "Check your internet connection and run `ruby_native login` again."
        else
          puts "Authorization timed out. Run `ruby_native login` again and approve"
          puts "the request in your browser."
        end
      end
    end
  end
end
