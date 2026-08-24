module RubyNative
  # Rack 2 carries Set-Cookie as one newline joined String, Rack 3 as an Array
  # of cookie strings. Rewrites must hand back whichever shape came in.
  module SetCookieHeader
    KEYS = ["set-cookie", "Set-Cookie"].freeze

    module_function

    def read(headers)
      raw = KEYS.map { |key| headers[key] }.compact.first
      case raw
      when Array then raw
      when String then raw.split("\n")
      else []
      end
    end

    def rewrite!(headers, &block)
      key = KEYS.find { |k| headers[k] }
      return unless key

      rewritten = read(headers).map(&block)
      headers[key] = headers[key].is_a?(Array) ? rewritten : rewritten.join("\n")
    end
  end
end
