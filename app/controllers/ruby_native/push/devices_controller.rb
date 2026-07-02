module RubyNative
  module Push
    class DevicesController < ::ApplicationController
      skip_forgery_protection

      def create
        device = ruby_native_user.push_devices.find_or_initialize_by(token: params[:token])
        device.update!(platform: params[:platform], name: params[:name])
        head :ok
      end

      private

      # Resolves the signed-in user via RubyNative.current_user_resolver, which is
      # either a controller method name (Symbol) or a callable run in the
      # controller. Defaults to `current_user`.
      def ruby_native_user
        resolver = RubyNative.current_user_resolver
        resolver.respond_to?(:call) ? instance_exec(&resolver) : send(resolver)
      end
    end
  end
end
