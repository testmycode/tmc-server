# frozen_string_literal: true

# Emailed links carry their token in the URL path, which Rails and Rack::Attack would log verbatim.
module SecretPathFilter
  TOKEN_SEGMENT = %r{(/reset_password/+|/users/+[^/]+/+(?:verify|destroy)/+)[^/?#]+}

  def self.filter(path)
    path.gsub(TOKEN_SEGMENT, '\1[FILTERED]')
  end
end

ActionDispatch::Request.prepend(Module.new do
  def filtered_path
    SecretPathFilter.filter(super)
  end
end)

Rails.application.config.filter_redirect << SecretPathFilter::TOKEN_SEGMENT
