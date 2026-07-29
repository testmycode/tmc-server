# frozen_string_literal: true

# Application secrets, read from config/secrets.yml.
#
# Replaces `Rails.application.secrets`, which Rails 7.1 deprecates (it warns once per
# process, from the first reader during boot) and Rails 7.2 removes outright.
#
# The deprecation points at `Rails.application.credentials` instead, but that is not a
# drop-in here: credentials wants an encrypted config/credentials.yml.enc plus a master
# key to decrypt it, and this app has neither. config/secrets.yml deliberately carries
# working plaintext defaults for development and test — so a fresh checkout boots and
# the suite runs with no key material to fetch — and reads everything else from ENV in
# production. Moving to credentials would mean distributing a master key to every
# deploy and every developer, and re-doing how production gets its values. That is a
# deployment decision, not a deprecation fix.
#
# So keep the file and read it the way Rails still supports: `config_for` parses the
# same per-environment, ERB-enabled YAML and returns an ActiveSupport::OrderedOptions,
# which is the dot-accessible, nil-for-missing-key object `Rails.application.secrets`
# already handed back. Call sites are unchanged apart from the receiver.
#
# Lives in lib/ rather than app/ because config/initializers/doorkeeper_openid_connect.rb
# needs it at boot, before app/ autoloading is safe to lean on. lib/ is on $LOAD_PATH,
# so `require 'app_secrets'` works from anywhere — the same way lib/submission_processor.rb
# and friends are used.
module AppSecrets
  class << self
    # Memoized: secrets.yml is only read at boot anyway ("be sure to restart your
    # server when you modify this file"), and re-running ERB per lookup would mean
    # re-reading the file on every introspection call.
    def config
      @config ||= Rails.application.config_for(:secrets)
    end

    # Reset the memo. For specs that need to observe a different secrets.yml; not
    # something application code should call.
    def reload!
      @config = nil
    end

    delegate_missing_to :config
  end
end
