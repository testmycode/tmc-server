module AuthorizeCollectionHelper
  # This method allows to authorize collections of items
  # TODO: Has to be tested with empty collections and other edge cases
  def authorize_collection(action, collection)
    @_authorized = true
    collection.each { |col| authorize! action, col }
  end
end
