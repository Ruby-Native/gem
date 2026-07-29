require "rails/generators"
require "rails/generators/migration"

module RubyNative
  module Generators
    class IapGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      # Must increment within a single run, or the second migration below collides
      # with the first on a bare `Time.now` timestamp.
      def self.next_migration_number(dirname)
        ActiveRecord::Migration.next_migration_number(current_migration_number(dirname) + 1)
      end

      # Re-running this generator on an app that already has the first migration
      # reports it identical and creates only what is missing, so it doubles as
      # the upgrade path.
      def copy_migrations
        migration_template "create_ruby_native_purchase_intents.rb",
          "db/migrate/create_ruby_native_purchase_intents.rb"
        migration_template "add_restored_transaction_id_to_ruby_native_purchase_intents.rb",
          "db/migrate/add_restored_transaction_id_to_ruby_native_purchase_intents.rb"
      end

      def print_next_steps
        say ""
        say "Ruby Native IAP installed!", :green
        say ""
        say "  1. Run migrations: bin/rails db:migrate"
        say "  2. Add your callback in config/initializers/ruby_native.rb:"
        say ""
        say '     RubyNative.on_subscription_change do |event|'
        say '       user = User.find_by(id: event.owner_token)'
        say '       user&.update!(subscribed: event.active?)'
        say '     end'
        say ""
        say "  3. Set your App Store Server Notification URL to:"
        say "     https://yourapp.com/native/webhooks/apple"
        say ""
      end
    end
  end
end
