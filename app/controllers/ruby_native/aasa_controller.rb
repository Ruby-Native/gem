module RubyNative
  class AasaController < ::ActionController::Base
    def show
      RubyNative.load_config if Rails.env.development?

      bundle_id = RubyNative.config&.dig(:ios, :bundle_id)
      team_id = RubyNative.config&.dig(:ios, :team_id)
      return head :not_found unless bundle_id.present? && team_id.present?

      app_id = "#{team_id}.#{bundle_id}"
      response.set_header("Cache-Control", "no-cache")
      render json: {
        applinks: {
          details: [
            { appIDs: [ app_id ], components: [ { "/": "*" } ] }
          ]
        },
        webcredentials: {
          apps: [ app_id ]
        }
      }
    end
  end
end
