# typed: false
# frozen_string_literal: true

# Doorkeeper autoloads its token and grant models on first use, so eager loading
# leaves them out of ActiveRecord::Base.descendants and their DSL RBIs vanish.
require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:after_initialize) do
  Doorkeeper::AccessGrant
  Doorkeeper::AccessToken
  Doorkeeper::Application
end
