
# frozen_string_literal: true

# See
# http://stackoverflow.com/questions/12243694/getting-error-exceeded-available-parameter-key-space
# or
# http://stackoverflow.com/questions/9122411/rails-javascript-too-many-parameter-keys-whats-a-good-way-to-normalize-f
#
# This file should be removed once everyone is using NB plugin 0.4.1+, which sends events in smaller batches.
#

if Rack::Utils.respond_to?('key_space_limit=')
  Rack::Utils.key_space_limit = 262_144 * 100
end
