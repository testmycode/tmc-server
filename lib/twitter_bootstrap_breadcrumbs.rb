# typed: strict
# frozen_string_literal: true

module BreadCrumbs
  extend T::Sig
  extend T::Helpers
  requires_ancestor { ActionController::Base }

  module ClassMethods
    extend T::Sig
    extend T::Helpers
    requires_ancestor { T.class_of(ActionController::Base) }

    # options: before_action options such as only:.
    sig { params(name: T.nilable(T.any(String, Symbol)), url: T.any(String, Symbol, Proc), options: T::Hash[Symbol, T.untyped]).void }
    def add_breadcrumb(name, url, options = {})
      class_name = self.name
      before_action options do |controller|
        crumb_name = name.is_a?(Symbol) ? controller.send(:translate_breadcrumb, name, class_name) : name
        controller.send :add_breadcrumb, crumb_name, url
      end
    end
  end

  mixes_in_class_methods(ClassMethods)

    protected
      # A Symbol name is an I18n key under breadcrumbs.<controller path>; a Symbol url names a
      # route helper to call.
      sig { params(name: T.nilable(T.any(String, Symbol)), url: T.any(String, Symbol, Proc), options: T::Hash[Symbol, T.untyped]).void }
      def add_breadcrumb(name, url = '', options = {})
        breadcrumbs = @breadcrumbs ||= T.let([], T.nilable(T::Array[T::Hash[Symbol, T.untyped]]))
        name = translate_breadcrumb(name, T.must(self.class.name)) if name.is_a?(Symbol)
        url = send(url) if url.is_a?(Symbol)
        breadcrumbs << { name: name, url: url, options: options }
      end

      sig { params(name: Symbol, class_name: String).returns(String) }
      def translate_breadcrumb(name, class_name)
        scope = [:breadcrumbs]
        namespace = class_name.underscore.split('/')
        T.must(namespace.last).sub!('_controller', '')
        scope += namespace

        I18n.t name, scope: scope
      end
end
