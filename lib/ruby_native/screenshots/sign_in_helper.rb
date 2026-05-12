module RubyNative
  module Screenshots
    # Yielded to the customer's `screenshot_sign_in` lambda. Exposes the
    # request, session, and cookies as public accessors so the lambda never
    # touches `ActionController` internals directly. `cookies` in particular
    # is private on `ActionController::Base` in Rails 8.1+, so customers
    # would otherwise have to fall back to `controller.send(:cookies)`.
    class SignInHelper
      def initialize(controller)
        @controller = controller
      end

      def cookies
        @controller.send(:cookies)
      end

      def request
        @controller.request
      end

      def session
        @controller.session
      end
    end
  end
end
