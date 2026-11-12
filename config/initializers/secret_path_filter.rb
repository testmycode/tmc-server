# typed: strict
# frozen_string_literal: true

# Emailed links carry their token in the URL path, which Rails and Rack::Attack would log verbatim.
module SecretPathFilter
  extend T::Sig

  TOKEN_SEGMENT = T.let(%r{(/reset_password/+|/users/+[^/]+/+(?:verify|destroy)/+)[^/?#]+}, Regexp)

  # +path+ with the token segments of emailed links replaced by [FILTERED].
  sig { params(path: String).returns(String) }
  def self.filter(path)
    path.gsub(TOKEN_SEGMENT, '\1[FILTERED]')
  end

  # Prepended to ActionDispatch::Request, whose filtered_path the request log prints.
  module RequestFilteredPath
    extend T::Sig
    extend T::Helpers
    requires_ancestor { ActionDispatch::Request }

    sig { returns(String) }
    def filtered_path
      SecretPathFilter.filter(super)
    end
  end
end

ActiveSupport.on_load(:action_dispatch_request) do
  T.bind(self, T.class_of(ActionDispatch::Request))
  prepend SecretPathFilter::RequestFilteredPath
end

Rails.application.config.filter_redirect << SecretPathFilter::TOKEN_SEGMENT
