module RubyNative
  class AssetlinksController < ::ActionController::Base
    def show
      RubyNative.load_config if Rails.env.development?

      package = RubyNative.config&.dig(:android, :package)
      # The Digital Asset Links spec wants uppercase colon-separated hex, so a
      # lowercase paste from keytool still verifies.
      fingerprints = Array(RubyNative.config&.dig(:android, :cert_fingerprint))
        .map { |fingerprint| fingerprint.to_s.strip.upcase }
        .reject(&:empty?)
      return head :not_found unless package.present? && fingerprints.present?

      response.set_header("Cache-Control", "no-cache")
      render json: [
        {
          relation: [
            "delegate_permission/common.handle_all_urls",
            "delegate_permission/common.get_login_creds"
          ],
          target: {
            namespace: "android_app",
            package_name: package,
            sha256_cert_fingerprints: fingerprints
          }
        }
      ]
    end
  end
end
