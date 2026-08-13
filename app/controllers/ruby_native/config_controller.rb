module RubyNative
  class ConfigController < ::ActionController::Base
    def show
      RubyNative.load_config if Rails.env.local?
      # The version header stays on the 404 so `ruby_native preview` can tell
      # missing config apart from an unmounted engine.
      response.set_header("X-Ruby-Native-Version", RubyNative::VERSION)

      config = RubyNative.config_as_json
      if config.nil?
        render json: { error: "config/ruby_native.yml is missing or empty" }, status: :not_found
      else
        render json: config
      end
    end
  end
end
