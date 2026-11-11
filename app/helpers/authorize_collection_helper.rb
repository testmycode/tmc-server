# typed: strict
# frozen_string_literal: true

module AuthorizeCollectionHelper
  extend T::Sig

  # This method allows to authorize collections of items
  # TODO: Has to be tested with empty collections and other edge cases
  sig { params(action: Symbol, collection: T::Enumerable[T.untyped]).void }
  def authorize_collection(action, collection)
    @_authorized = T.let(true, T.nilable(T::Boolean))
    collection.each { |col| authorize! action, col }
  end
end
