# typed: false
# frozen_string_literal: true

# Generated RBIs must not depend on the gitignored config/site.yml (e.g. pghero_enabled gates a route mount).
# Loaded before the application, which requires this same file and so keeps the patched class.
require 'sorbet-runtime'
require_relative '../../../app/models/site_setting'

SiteSetting.singleton_class.prepend(Module.new do
  private
    def settings_files
      super.select { |path| path.end_with?('/site.defaults.yml') }
    end
end)
