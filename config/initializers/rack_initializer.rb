
# See
# http://stackoverflow.com/questions/12243694/getting-error-exceeded-available-parameter-key-space
# or
# http://stackoverflow.com/questions/9122411/rails-javascript-too-many-parameter-keys-whats-a-good-way-to-normalize-f

if Rack::Utils.respond_to?("key_space_limit=")
  Rack::Utils.key_space_limit = 262144
end
