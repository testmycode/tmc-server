# typed: false
# frozen_string_literal: true

# Tapioca includes T::Sig into Module, which puts sorbet-runtime's hook below ActiveRecord's
# singleton_method_added. Before Rails 7.2.1 (rails/rails#52634) that didn't call super, so a sig on
# `def self.foo` in a model was never consumed and the next `sig` raised "sig twice".
require 'active_record'

if ActiveRecord.gem_version < Gem::Version.new('7.2.1')
  module ActiveRecord::Scoping::Named::ClassMethods
    private
      def singleton_method_added(name)
        super
        generate_relation_method(name) if Kernel.respond_to?(name) && !ActiveRecord::Relation.method_defined?(name)
      end
  end
end
