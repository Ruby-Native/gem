require "open3"
require "net/http"
require "uri"
require "resolv"

module RubyNative
  class CLI
    class Preview
      TUNNEL_URL_PATTERN = %r{https://[a-z0-9-]+\.trycloudflare\.com}
      CONFIG_PATH = "/native/config.json"
      TUNNEL_READY_TIMEOUT = 60
      TUNNEL_POLL_INTERVAL = 1
      PUBLIC_NAMESERVERS = ["1.1.1.1", "8.8.8.8"].freeze

      def initialize(argv)
        @port = parse_port(argv)
      end

      def run
        check_cloudflared!
        check_local_server!
        start_tunnel
      end

      private

      def check_local_server!
        uri = URI("http://localhost:#{@port}#{CONFIG_PATH}")
        response = fetch_config_response(uri)

        return if response.is_a?(Net::HTTPSuccess)

        puts "Rails server is running on port #{@port}, but #{CONFIG_PATH} returned #{response.code}."
        puts ""
        puts "Make sure the ruby_native gem is installed and mounted:"
        puts "  https://rubynative.com/docs/install"
        exit 1
      rescue Errno::ECONNREFUSED
        puts "Nothing is running on port #{@port}."
        puts ""
        puts "Start your Rails server in another terminal:"
        puts "  bin/rails server -p #{@port}"
        exit 1
      rescue => e
        puts "Could not reach http://localhost:#{@port}#{CONFIG_PATH}: #{e.message}"
        exit 1
      end

      def fetch_config_response(uri, ip: nil)
        http = Net::HTTP.new(uri.host, uri.port)
        http.ipaddr = ip if ip
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 2
        http.read_timeout = 5
        http.start { http.get(uri.request_uri) }
      end

      def wait_for_tunnel(url)
        uri = URI("#{url}#{CONFIG_PATH}")
        deadline = monotonic_now + TUNNEL_READY_TIMEOUT
        ip = nil

        print "Waiting for tunnel..."
        loop do
          begin
            ip ||= resolve_via_public_dns(uri.host)
            response = fetch_config_response(uri, ip: ip)
            if response.is_a?(Net::HTTPSuccess)
              puts " ready."
              return
            end
          rescue Resolv::ResolvError, Resolv::ResolvTimeout, StandardError
            # Keep polling.
          end

          if monotonic_now >= deadline
            puts ""
            puts "Tunnel did not respond within #{TUNNEL_READY_TIMEOUT}s at #{url}."
            puts "Showing the URL anyway. It may take a few more seconds before scanning works."
            return
          end

          print "."
          sleep TUNNEL_POLL_INTERVAL
        end
      end

      def resolve_via_public_dns(host)
        resolver = Resolv::DNS.new(nameserver: PUBLIC_NAMESERVERS)
        resolver.timeouts = [2, 4]
        addresses = resolver.getaddresses(host)
        raise Resolv::ResolvError, "no A/AAAA record for #{host}" if addresses.empty?
        addresses.first.to_s
      ensure
        resolver&.close
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def parse_port(argv)
        index = argv.index("--port")
        if index
          argv[index + 1]&.to_i || 3000
        else
          3000
        end
      end

      def check_cloudflared!
        unless system("which cloudflared > /dev/null 2>&1")
          puts "cloudflared is not installed."
          puts ""
          puts "Install it with Homebrew:"
          puts "  brew install cloudflare/cloudflare/cloudflared"
          puts ""
          puts "Or see: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
          exit 1
        end
      end

      def start_tunnel
        puts "Starting tunnel to http://localhost:#{@port}..."
        puts "Make sure your Rails server is running on port #{@port} in another terminal."
        puts ""

        stdin, stdout_err, wait_thread = Open3.popen2e(
          "cloudflared", "tunnel", "--url", "http://localhost:#{@port}"
        )
        stdin.close

        @tunnel_pid = wait_thread.pid
        trap_interrupt

        tunnel_url = nil

        stdout_err.each_line do |line|
          if line =~ TUNNEL_URL_PATTERN
            tunnel_url = line[TUNNEL_URL_PATTERN]
            wait_for_tunnel(tunnel_url)
            display_qr(tunnel_url)
          end
        end
      rescue Interrupt
        # Handled by trap
      ensure
        kill_tunnel
      end

      def display_qr(url)
        require "rqrcode"

        qr = RQRCode::QRCode.new(url, level: :l)
        modules = qr.modules
        size = modules.length
        quiet_h = 4
        quiet_v = 2

        dark = "██"
        light = "  "

        puts ""
        (0...(size + quiet_v * 2)).each do |r|
          line = +""
          (0...(size + quiet_h * 2)).each do |c|
            mr = r - quiet_v
            mc = c - quiet_h
            inside = mr >= 0 && mr < size && mc >= 0 && mc < size
            line << (inside && modules[mr][mc] ? dark : light)
          end
          puts line
        end
        puts ""
        puts url
        puts ""
        puts "Scan the QR code or paste the URL into the Ruby Native Preview app."
        puts "Keep this running and your Rails server on port #{@port} in another terminal."
        puts "Press Ctrl+C to stop."
      end

      def trap_interrupt
        Signal.trap("INT") do
          kill_tunnel
          exit 0
        end
      end

      def kill_tunnel
        return unless @tunnel_pid
        Process.kill("TERM", @tunnel_pid)
        Process.wait(@tunnel_pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already exited.
      end
    end
  end
end
